package main

import (
	"log"
	"os"
    "fmt"
    "net/http"
    "math"

	"github.com/gin-gonic/gin"
	_ "github.com/heroku/x/hmetrics/onload"
)

func main() {
	port := os.Getenv("PORT")

	if port == "" {
		log.Fatal("$PORT must be set")
	}

	router := gin.New()
	router.Use(gin.Logger())
	router.LoadHTMLGlob("templates/*.tmpl.html")
	router.Static("/static", "static")

	router.GET("/", func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.tmpl.html", nil)
	})

	router.GET("/api/v2/subjects", func(c *gin.Context) {
		ch := make(chan *Subjects)
		go getSubjects(ch)
		subjects := <-ch
		
		fmt.Printf("%-v\n", subjectsDataMap[19])
		fmt.Printf("%d subjects pages in total\n", subjects.Pages.Last)
		fmt.Printf("data has length %d\n", len(subjects.Data))
		c.JSON(200, subjects)
	})

	router.GET("/srs/status", func(c *gin.Context) {
		chSubjects := make(chan *Subjects)
		go getSubjects(chSubjects)

		chReviewStatistics := make(chan *ReviewStatistics)
		go getReviewStatistics(chReviewStatistics)

		chAssignments := make(chan *Assignments)
		go getAssignments(chAssignments)

		chSummary := make(chan *Summary)
		go getSummary(chSummary)
		
		assignments := <-chAssignments
		assignmentsDataMap := make(map[int]AssignmentsData)
		for i := 0; i<len(assignments.Data); i++ {
	        assignmentsDataMap[assignments.Data[i].Data.SubjectID] = assignments.Data[i]
	    }
		<-chSubjects
		reviewStatistics := <-chReviewStatistics
		<-chSummary

		dashboard := Dashboard{}
		dashboard.Levels.Order = []string{ "apprentice", "guru", "master", "enlightened", "burned" }

		leeches := []Leech{}

		for i := 0; i<len(reviewStatistics.Data); i++ {
			reviewStatistic := reviewStatistics.Data[i]
			if reviewStatistic.Data.SubjectType == "radical" {
				continue
			}
			if (reviewStatistic.Data.MeaningIncorrect + reviewStatistic.Data.MeaningCorrect == 0) {
				continue
			}
			if (reviewStatistic.Data.MeaningCorrect < 4) {
				// has not yet made it to Guru (approximate)
				continue;
			}

			assignment := assignmentsDataMap[reviewStatistic.Data.SubjectID]

			if (len(assignment.Data.BurnedAt) > 0) {
				continue;
			}

            meaningScore := float64(reviewStatistic.Data.MeaningIncorrect) / math.Pow(float64(reviewStatistic.Data.MeaningCurrentStreak), 1.5)
            readingScore := float64(reviewStatistic.Data.ReadingIncorrect) / math.Pow(float64(reviewStatistic.Data.ReadingCurrentStreak), 1.5)
            
            if (meaningScore < 1.0 && readingScore < 1.0) {
            	continue;
            }

			subject := subjectsDataMap[reviewStatistic.Data.SubjectID]

			leech := Leech{}

			if len(subject.Data.Character) > 0 {
				leech.Name = subject.Data.Character 
			} else {
				leech.Name = subject.Data.Characters
			}

			for j := 0; j<len(subject.Data.Meanings); j++ {
				if (subject.Data.Meanings[j].Primary) {
					leech.PrimaryMeaning = subject.Data.Meanings[j].Meaning
					break
				}
			}

			for j := 0; j<len(subject.Data.Readings); j++ {
				if (subject.Data.Readings[j].Primary) {
					leech.PrimaryReading = subject.Data.Readings[j].Reading
					break
				}
			}

			leech.SrsStage = assignment.Data.SrsStage			
			leech.SrsStageName = assignment.Data.SrsStageName

			if (meaningScore > readingScore) {
				leech.WorstType = "meaning"
				leech.WorstScore = meaningScore
				leech.WorstCurrentStreak = reviewStatistic.Data.MeaningCurrentStreak
				leech.WorstIncorrect = reviewStatistic.Data.MeaningIncorrect
			} else {
				leech.WorstType = "reading"
				leech.WorstScore = readingScore
				leech.WorstCurrentStreak = reviewStatistic.Data.ReadingCurrentStreak
				leech.WorstIncorrect = reviewStatistic.Data.ReadingIncorrect
			}

			if leech.WorstCurrentStreak > 1 {
                leech.Trend = -1 
			} else if leech.WorstIncorrect > 1 {
                leech.Trend = 1
			} else {
            	leech.Trend = 0
            }
    
    		leech.SubjectID = subject.ID
			leech.SubjectType = subject.Object

			leeches = append(leeches, leech)
			fmt.Printf("%-v\n", leech)
		}

		dashboard.ReviewOrder = leeches
		c.JSON(200, dashboard)
	})

	router.Run(":" + port)
}
