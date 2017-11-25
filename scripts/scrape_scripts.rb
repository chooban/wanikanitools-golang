require 'json'

scripts = JSON.parse(File.read('data/scripts.json'))['scripts']

topicIdToScript = Hash.new

scripts.each do |url, script|
    filename = "data/script.#{script['topic_id']}.html"
    puts filename
    html = File.read(filename)

    m = html.match(/<h2>([^<]+)<\/h2>.*?<p id="script-description">([^<]+)<\/p>.*?<dd class="script-show-total-installs"><span>([^<]+)<\/span><\/dd>.*?<dd class="script-show-version"><span>([^<]+)<\/span><\/dd>/m)

    if m
        script['name'] = m[1]
        script['description'] = m[2]
        script['installs'] = m[3].gsub(/,/, '').to_i
        script['version'] = m[4]
        topicIdToScript[script['topic_id']] = script
        script['globalVariables'] = []
    else
        puts "Failed regex! (#{script['script_url']})"
        `rm #{filename}`
    end
end

# raw = `grep -E '^\s*([a-zA-Z0-9]+\s*=\s*\{\})|(window\\.[a-zA-Z0-9]+\s*=)' data/*.js | grep -v window.appStoreRegistry | grep -v 'window.appStoreRegistry' | grep -v 'window.location' | grep -v 'window.onload' | grep -v 'window.onresize' | grep -v 'window.onbeforeunload' | grep -v 'window.onpopstate'`

raw = `grep -E '^\s*(window\\.)?[a-zA-Z0-9]+\s*=\s*' data/*.js`

raw.lines.each do |line|
    filename, code = line.split(':')
    topic_id = filename.match(/^data\/script\.([0-9]+)\.js$/)[1].to_i
    var = code.strip.split('=')[0].strip.sub("window.", "")

    puts filename
    puts code
    puts "    #{var}"

    topicIdToScript[topic_id]['globalVariables'] = (topicIdToScript[topic_id]['globalVariables'] << var).uniq
end

globalVariables = []

scripts.each do |url, script|
    puts globalVariables.inspect
    puts script['globalVariables'].inspect
    globalVariables += script['globalVariables']
end

sharedGlobalVariables = globalVariables.group_by { |i| i }.select { |k,v| v.size > 2 }
incognitoWanikaniWindowVariables = ['postMessage', 'blur', 'focus', 'close', 'frames', 'self', 'window', 'parent', 'opener', 'top', 'length', 'closed', 'location', 'document', 'origin', 'name', 'history', 'locationbar', 'menubar', 'personalbar', 'scrollbars', 'statusbar', 'toolbar', 'status', 'frameElement', 'navigator', 'applicationCache', 'customElements', 'external', 'screen', 'innerWidth', 'innerHeight', 'scrollX', 'pageXOffset', 'scrollY', 'pageYOffset', 'screenX', 'screenY', 'outerWidth', 'outerHeight', 'devicePixelRatio', 'clientInformation', 'screenLeft', 'screenTop', 'defaultStatus', 'defaultstatus', 'styleMedia', 'onanimationend', 'onanimationiteration', 'onanimationstart', 'onsearch', 'ontransitionend', 'onwebkitanimationend', 'onwebkitanimationiteration', 'onwebkitanimationstart', 'onwebkittransitionend', 'isSecureContext', 'onabort', 'onblur', 'oncancel', 'oncanplay', 'oncanplaythrough', 'onchange', 'onclick', 'onclose', 'oncontextmenu', 'oncuechange', 'ondblclick', 'ondrag', 'ondragend', 'ondragenter', 'ondragleave', 'ondragover', 'ondragstart', 'ondrop', 'ondurationchange', 'onemptied', 'onended', 'onerror', 'onfocus', 'oninput', 'oninvalid', 'onkeydown', 'onkeypress', 'onkeyup', 'onload', 'onloadeddata', 'onloadedmetadata', 'onloadstart', 'onmousedown', 'onmouseenter', 'onmouseleave', 'onmousemove', 'onmouseout', 'onmouseover', 'onmouseup', 'onmousewheel', 'onpause', 'onplay', 'onplaying', 'onprogress', 'onratechange', 'onreset', 'onresize', 'onscroll', 'onseeked', 'onseeking', 'onselect', 'onstalled', 'onsubmit', 'onsuspend', 'ontimeupdate', 'ontoggle', 'onvolumechange', 'onwaiting', 'onwheel', 'ongotpointercapture', 'onlostpointercapture', 'onpointerdown', 'onpointermove', 'onpointerup', 'onpointercancel', 'onpointerover', 'onpointerout', 'onpointerenter', 'onpointerleave', 'onbeforeunload', 'onhashchange', 'onlanguagechange', 'onmessage', 'onmessageerror', 'onoffline', 'ononline', 'onpagehide', 'onpageshow', 'onpopstate', 'onrejectionhandled', 'onstorage', 'onunhandledrejection', 'onunload', 'performance', 'stop', 'open', 'alert', 'confirm', 'prompt', 'print', 'requestAnimationFrame', 'cancelAnimationFrame', 'requestIdleCallback', 'cancelIdleCallback', 'captureEvents', 'releaseEvents', 'getComputedStyle', 'matchMedia', 'moveTo', 'moveBy', 'resizeTo', 'resizeBy', 'getSelection', 'find', 'getMatchedCSSRules', 'webkitRequestAnimationFrame', 'webkitCancelAnimationFrame', 'btoa', 'atob', 'setTimeout', 'clearTimeout', 'setInterval', 'clearInterval', 'createImageBitmap', 'scroll', 'scrollTo', 'scrollBy', 'onappinstalled', 'onbeforeinstallprompt', 'caches', 'crypto', 'ondevicemotion', 'ondeviceorientation', 'ondeviceorientationabsolute', 'indexedDB', 'webkitStorageInfo', 'sessionStorage', 'localStorage', 'fetch', 'onauxclick', 'visualViewport', 'speechSynthesis', 'webkitRequestFileSystem', 'webkitResolveLocalFileSystemURL', 'openDatabase', 'chrome', 'NREUM', 'newrelic', '__nr_require', 'font', '$', 'jQuery', 'jQuery112405201788882720262', 'Animation', 'AudioPlay', 'Charting', 'Counts', 'Dashboard', 'DateTime', 'Form', 'CharacterGrid', 'InfoTip', 'Lattice', 'Misc', 'NavBar', 'Profile', 'Progression', 'Search', 'TextStyle', 'Notes', 'UserSynonyms', 'GoogleAnalyticsObject', 'ga', 'gaplugins', 'gaGlobal', 'gaData']

scripts.each do |url, script|
    script['globalVariables'].reject! { |var| sharedGlobalVariables.has_key?(var) || incognitoWanikaniWindowVariables.include?(var) }
end


File.write('data/scripts.json', JSON.generate({scripts: scripts}))

# excluded scripts
scripts.delete("https://greasyfork.org/en/scripts/35387-wanikani-app-store")
scripts.delete("https://greasyfork.org/en/scripts/7007-wanikani-burn-reviews")

File.write('../static/scripts.json', JSON.pretty_generate(scripts.values, indent: '  '))