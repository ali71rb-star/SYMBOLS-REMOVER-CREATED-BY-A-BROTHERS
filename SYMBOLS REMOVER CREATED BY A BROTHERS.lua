require "import"
import "android.widget.*"
import "android.view.*"
import "android.app.*"
import "android.content.*"
import "android.os.*"
import "android.text.*"
import "android.graphics.Typeface"
import "android.net.Uri"

-- سیشن ویری ایبلز
local totalDots, totalCommas, totalLines, totalEmojis, totalNumbers, totalSymbols = 0, 0, 0, 0, 0, 0
local lastCleanText = ""
local lastSettingsHash = ""
-- اناؤنسمنٹ ٹریکر
local sessionReported = {emoji=false, num=false, sym=false, dot=false, comma=false, line=false}

local function showSymbolRemover()
    local cm = service.getSystemService(Context.CLIPBOARD_SERVICE)
    local pref = service.getSharedPreferences("A_BROTHERS_PREFS", Context.MODE_PRIVATE)
    local editPref = pref.edit()
    
    local keepSpecial = pref.getBoolean("keep_special_state", false)
    local keepEmoji = pref.getBoolean("keep_emoji_state", true)
    local keepNumbers = pref.getBoolean("keep_numbers_state", true)
    local keepSymbols = pref.getBoolean("keep_symbols_state", true)
    local announceState = pref.getBoolean("announce_state", true)
    local masterState = pref.getBoolean("master_state", true)
    
    local scrollView = ScrollView(service)
    scrollView.setFillViewport(true)
    
    local mainLayout = LinearLayout(service)
    mainLayout.setOrientation(LinearLayout.VERTICAL)
    mainLayout.setPadding(35, 35, 35, 35)
    mainLayout.setBackgroundColor(0xFFFFFFFF)
    scrollView.addView(mainLayout)

    local titleText = TextView(service)
    titleText.setText("SYMBOLS REMOVER CREATED BY A BROTHERS")
    titleText.setGravity(Gravity.CENTER)
    titleText.setTextSize(18)
    titleText.setTextColor(0xFF000000)
    titleText.setTypeface(Typeface.DEFAULT_BOLD)
    mainLayout.addView(titleText)

    local editBox = EditText(service)
    editBox.setHint("Paste or type text here...")
    editBox.setGravity(Gravity.TOP)
    editBox.setBackgroundColor(0xFFF5F5F5)
    editBox.setMinLines(10)
    editBox.setHorizontallyScrolling(false)
    editBox.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE)
    
    local lpEdit = LinearLayout.LayoutParams(-1, -2)
    lpEdit.setMargins(0, 10, 0, 5)
    editBox.setLayoutParams(lpEdit)
    mainLayout.addView(editBox)

    local infoLayout = LinearLayout(service)
    infoLayout.setOrientation(LinearLayout.HORIZONTAL)
    mainLayout.addView(infoLayout)

    local limitText = TextView(service)
    limitText.setText("0 / 20000")
    limitText.setTextColor(0xFF777777)
    limitText.setPadding(0, 0, 10, 0)
    infoLayout.addView(limitText)

    local removedStatusText = TextView(service)
    removedStatusText.setText("Removed 0 symbols 0 dots 0 commas 0 lines 0 numbers 0 emojis")
    removedStatusText.setTextColor(0xFFFF5722)
    removedStatusText.setTextSize(10)
    removedStatusText.setTypeface(Typeface.DEFAULT_BOLD)
    infoLayout.addView(removedStatusText)

    local function updateCounts()
        local txt = tostring(editBox.getText())
        limitText.setText(string.format("%d / 20000", utf8.len(txt) or 0))
    end

    editBox.addTextChangedListener(TextWatcher{onTextChanged = function() updateCounts() end})

    local function addBtn(text, color)
        local b = Button(service)
        b.setText(text)
        b.setBackgroundColor(color)
        b.setTextColor(0xFFFFFFFF)
        local lpBtn = LinearLayout.LayoutParams(-1, -2)
        lpBtn.setMargins(0, 5, 0, 5)
        b.setLayoutParams(lpBtn)
        mainLayout.addView(b)
        return b
    end

    addBtn("Paste Text", 0xFF4CAF50).onClick = function()
        local clip = cm.getPrimaryClip()
        if clip and clip.getItemCount() > 0 then
            editBox.setText(tostring(clip.getItemAt(0).getText()))
            sessionReported = {emoji=false, num=false, sym=false, dot=false, comma=false, line=false}
            service.speak("Pasted")
        end
    end
    
    local btnToggle = addBtn("", 0xFFFF9800)
    local btnEmojiToggle = addBtn("", 0xFF00BCD4)
    local btnSymToggle = addBtn("", 0xFF009688)
    local btnNumToggle = addBtn("", 0xFF3F51B5)
    local btnMaster = addBtn("REMOVE EMOJIS NUMBERS AND SYMBOLS", 0xFF673AB7) 

    local function refreshToggle()
        btnToggle.setText(keepSpecial and "REMOVE DOTS COMMAS AND LINES ON" or "REMOVE DOTS COMMAS AND LINES OFF")
        btnToggle.setBackgroundColor(keepSpecial and 0xFFE65100 or 0xFFFF9800)
    end

    local function refreshEmojiToggle()
        btnEmojiToggle.setText(keepEmoji and "REMOVE EMOJIS ON" or "REMOVE EMOJIS OFF")
        btnEmojiToggle.setBackgroundColor(keepEmoji and 0xFF0097A7 or 0xFF00BCD4)
    end

    local function refreshSymToggle()
        btnSymToggle.setText(keepSymbols and "REMOVE SYMBOLS ON" or "REMOVE SYMBOLS OFF")
        btnSymToggle.setBackgroundColor(keepSymbols and 0xFF00796B or 0xFF009688)
    end

    local function refreshNumToggle()
        btnNumToggle.setText(keepNumbers and "REMOVE ALL NUMBERS ON" or "REMOVE ALL NUMBERS OFF")
        btnNumToggle.setBackgroundColor(keepNumbers and 0xFF1A237E or 0xFF3F51B5)
    end

    local function refreshMaster()
        btnMaster.setText("REMOVE EMOJIS NUMBERS AND SYMBOLS " .. (masterState and "ON" or "OFF"))
        btnMaster.setBackgroundColor(masterState and 0xFF4527A0 or 0xFF673AB7)
    end

    refreshToggle()
    refreshEmojiToggle()
    refreshSymToggle()
    refreshNumToggle()
    refreshMaster()

    local btnAnnounceToggle = addBtn("", 0xFF795548)
    local function refreshAnnounceToggle()
        btnAnnounceToggle.setText(announceState and "VOICE REPORT MODE ON" or "VOICE REPORT MODE OFF")
        btnAnnounceToggle.setBackgroundColor(announceState and 0xFF4E342E or 0xFF795548)
    end
    refreshAnnounceToggle()

    btnToggle.onClick = function()
        keepSpecial = not keepSpecial
        editPref.putBoolean("keep_special_state", keepSpecial).commit()
        refreshToggle()
        service.speak(keepSpecial and "Special removal enabled" or "Special removal disabled")
    end

    btnEmojiToggle.onClick = function()
        keepEmoji = not keepEmoji
        editPref.putBoolean("keep_emoji_state", keepEmoji).commit()
        refreshEmojiToggle()
        service.speak(keepEmoji and "Emoji removal enabled" or "Emoji removal disabled")
    end

    btnSymToggle.onClick = function()
        keepSymbols = not keepSymbols
        editPref.putBoolean("keep_symbols_state", keepSymbols).commit()
        refreshSymToggle()
        service.speak(keepSymbols and "Symbols removal enabled" or "Symbols removal disabled")
    end

    btnNumToggle.onClick = function()
        keepNumbers = not keepNumbers
        editPref.putBoolean("keep_numbers_state", keepNumbers).commit()
        refreshNumToggle()
        service.speak(keepNumbers and "Numbers removal enabled" or "Numbers removal disabled")
    end

    btnMaster.onClick = function()
        masterState = not masterState
        keepEmoji, keepNumbers, keepSymbols = masterState, masterState, masterState
        editPref.putBoolean("master_state", masterState)
        editPref.putBoolean("keep_emoji_state", keepEmoji)
        editPref.putBoolean("keep_numbers_state", keepNumbers)
        editPref.putBoolean("keep_symbols_state", keepSymbols).commit()
        refreshEmojiToggle()
        refreshNumToggle()
        refreshSymToggle()
        refreshMaster()
        service.speak(masterState and "Master removal enabled" or "Master removal disabled")
    end

    btnAnnounceToggle.onClick = function()
        announceState = not announceState
        editPref.putBoolean("announce_state", announceState).commit()
        refreshAnnounceToggle()
        service.speak(announceState and "Voice report enabled" or "Voice report disabled")
    end

    local btnClean = addBtn("Deep Clean and Copy", 0xFF2196F3)
    local btnClear = addBtn("CLEAR TEXT AND RESET STATS", 0xFFF44336)
    local btnAbout = addBtn("About", 0xFF9C27B0)
    local btnHelp = addBtn("Help and Feedback", 0xFF25D366)
    local btnExit = addBtn("EXIT", 0xFF607D8B)

    local dialog = AlertDialog.Builder(service).setView(scrollView).setCancelable(false).create()
    dialog.getWindow().setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY)
    dialog.show()

    btnClean.onClick = function()
        local rawText = tostring(editBox.getText())
        if rawText == "" then service.speak("Text box is empty") return end

        if not (keepSpecial or keepEmoji or keepNumbers or keepSymbols) then
            service.speak("Please turn on at least one option first")
            return
        end

        local currentSettings = tostring(keepSpecial)..tostring(keepEmoji)..tostring(keepNumbers)..tostring(keepSymbols)
        
        local needsReport = false
        if keepEmoji and not sessionReported.emoji then needsReport = true end
        if keepNumbers and not sessionReported.num then needsReport = true end
        if keepSymbols and not sessionReported.sym then needsReport = true end
        if keepSpecial and (not sessionReported.dot or not sessionReported.comma or not sessionReported.line) then needsReport = true end

        if rawText == lastCleanText and currentSettings == lastSettingsHash and not needsReport then
            service.speak("Already clean")
            cm.setPrimaryClip(ClipData.newPlainText("clean", rawText))
            return
        end

        service.speak("Scanning")
        task(400, function()
            local resultTable = {}
            local cDot, cComma, cLine, cEmoji, cNum, cSym = 0, 0, 0, 0, 0, 0
            
            for char in rawText:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
                local shouldRemove = false
                local isEmoji = char:match("[\240-\243][\128-\191][\128-\191][\128-\191]") or char:match("[\226-\227][\128-\191][\128-\191]")
                
                if isEmoji then 
                    if keepEmoji then shouldRemove = true; cEmoji = cEmoji + 1 end
                elseif char:match("%d") then 
                    if keepNumbers then shouldRemove = true; cNum = cNum + 1 end
                elseif char == "." then 
                    if keepSpecial then shouldRemove = true; cDot = cDot + 1 end
                elseif char == "," or char == "،" then 
                    if keepSpecial then shouldRemove = true; cComma = cComma + 1 end
                elseif char == "\n" or char == "\r" then 
                    if keepSpecial then shouldRemove = true; cLine = cLine + 1 end
                elseif char:match("[%a\216-\219\161-\191]") or char == " " then 
                    shouldRemove = false
                else 
                    if keepSymbols then shouldRemove = true; cSym = cSym + 1 end
                end

                if not shouldRemove then table.insert(resultTable, char) end
            end
            
            local cleanText = table.concat(resultTable)
            cleanText = cleanText:gsub("^ +", ""):gsub(" +$", "")

            totalDots, totalCommas, totalLines, totalEmojis, totalNumbers, totalSymbols = totalDots+cDot, totalCommas+cComma, totalLines+cLine, totalEmojis+cEmoji, totalNumbers+cNum, totalSymbols+cSym
            removedStatusText.setText(string.format("Removed %d symbols %d dots %d commas %d lines %d numbers %d emojis", totalSymbols, totalDots, totalCommas, totalLines, totalNumbers, totalEmojis))
            
            editBox.setText(cleanText)
            cm.setPrimaryClip(ClipData.newPlainText("clean", cleanText))
            
            if announceState then
                local report = {}
                if keepEmoji and not sessionReported.emoji then
                    table.insert(report, cEmoji .. " emojis")
                    sessionReported.emoji = true
                end
                if keepNumbers and not sessionReported.num then
                    table.insert(report, cNum .. " numbers")
                    sessionReported.num = true
                end
                if keepSymbols and not sessionReported.sym then
                    table.insert(report, cSym .. " symbols")
                    sessionReported.sym = true
                end
                if keepSpecial then
                    if not sessionReported.dot then table.insert(report, cDot .. " dots"); sessionReported.dot = true end
                    if not sessionReported.comma then table.insert(report, cComma .. " commas"); sessionReported.comma = true end
                    if not sessionReported.line then table.insert(report, cLine .. " lines"); sessionReported.line = true end
                end
                
                if #report > 0 then
                    local finalMsg = "Text cleaning successfully. " .. table.concat(report, ", ") .. " removed. Text copied to clipboard successfully"
                    service.speak(finalMsg)
                else
                    service.speak("Already clean. Text copied to clipboard successfully")
                end
            else
                service.speak("Text copied to clipboard successfully")
            end
            
            lastCleanText, lastSettingsHash = cleanText, currentSettings
        end)
    end

    btnClear.onClick = function() 
        local currentBoxText = tostring(editBox.getText())
        if currentBoxText == "" then 
            service.speak("Text box is already empty")
            return 
        end
        
        editBox.setText("")
        totalDots, totalCommas, totalLines, totalEmojis, totalNumbers, totalSymbols = 0, 0, 0, 0, 0, 0
        lastCleanText, lastSettingsHash = "", ""
        sessionReported = {emoji=false, num=false, sym=false, dot=false, comma=false, line=false}
        removedStatusText.setText("Removed 0 symbols 0 dots 0 commas 0 lines 0 numbers 0 emojis")
        service.speak("Cleared and stats reset successfully") 
    end

    btnAbout.onClick = function()
        local aboutMsg = "This extension is developed by A BROTHERS TEAM to help you clean your text easily. It is a very simple and powerful extension that removes all unwanted symbols, emojis, and numbers from your sentences. Sometimes text looks very messy with too many dots, commas, or icons, and this extension makes it clean and professional with just one click. It uses a smart system that remembers what it has already cleaned, so it only tells you about new things. Our team created this extension for people who want high-quality text without any manual work. Thank you for using our extension."
        local adb = AlertDialog.Builder(service)
        adb.setTitle("SYMBOLS REMOVER")
        adb.setMessage(aboutMsg)
        adb.setPositiveButton("OK", nil)
        local ad = adb.create()
        ad.getWindow().setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY)
        ad.show()
    end

    btnHelp.onClick = function()
        local waMsg = "Hello A BROTHERS TEAM, I have been using your 'Symbols Remover' extension and I am genuinely impressed by its seamless performance and precision. The advanced features and user-friendly interface make it a top-tier tool for text optimization. I would love to discuss its impressive functionality with you and share some detailed feedback on my experience."
        local intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://api.whatsapp.com/send?phone=923477583735&text=" .. Uri.encode(waMsg)))
        intent.setPackage("com.whatsapp").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        pcall(function() service.startActivity(intent) dialog.dismiss() end)
    end

    btnExit.onClick = function() dialog.dismiss() end
end

showSymbolRemover()