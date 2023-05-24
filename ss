//@version=5
//Thanks For Ogirinal Source Script From mladen for Engulfing Script and @KP_House, @JusInNovel, @jdehorty for Dashboard
//and Indicator Original From X4815162342 MA TYPE Cross Edit For Forex Engulfing and HH LL Trading Style

//Let's Me Explain About This Indicator
//  LightGreen Diamond "3Engulfing" is Bullish Confrim Engulfing 3 Candle
//  LightRed Diamond "3Engulfing" is Bearish Confrim Engulfing 3 Candle
//  Yellow ArrowUp is Normal Bullish Engulfing Candle
//  White ArrowDown is Normal Bearish Engulfing Candle
//  UpperBandLine, MiddleBandLine, LowerBandLine is Range Of Swing Price
//  Little Green Triangle is Signal To Buy
//  Little Red Triangle is Signal To Sell

//How To Use Indicator For Trading
//1. Confrim Signal Step
//  1.1) Bullish Trend
//      1.1.1) If Close Price < LowerBandLine
//      1.1.2) Must Have LightGreen Diamond "3Engulfing"
//      1.1.3) Direction Of BandLine are Up like this (↗)
//      1.1.4) Have a Cluster of Green Triangle
//      1.1.5) Sto Background Color is Green
//      **1.1.6) It's Good If Have a Yellow Direction Arrow Up (↗) but If Not Have a Yellow Direction Arrow Up (↗) No Problem
//  1.2) Bearish Trend
//      1.2.1) If Close Price > UpperBandLine
//      1.2.2) Must Have LightRed Diamond "3Engulfing"
//      1.2.3) Direction Of BandLine are Down like this (↘)
//      1.2.4) Have a Cluster of Red Triangle
//      1.1.5) Sto Background Color is Red
//      **1.2.6) It's Good If Have a White Direction Arrow Down (↘) but If Not Have a White Direction Arrow Down (↘) No Problem
//2. Trend Following for Short-Term/Mid-Term
//  2.1) Bullish Follow
//      2.1.1) Have a Cluster of Green Triangle
//      2.1.2) Have a Yellow Direction Arrow Up (↗) >>(or)<< LightGreen Diamond "3Engulfing"
//  2.2) Bearish Follow
//      2.2.1) Have a Cluster of Red Triangle
//      2.2.2) Have a White Direction Arrow Down (↘) >>(or)<< LightRed Diamond "3Engulfing"
//3. TP and SL - If You Following Trend or Confirm Signal
//  3.1) Bullish TP/SL
//      3.1.1) TakeProfit (TP)
//          3.1.1.1) Can TP IF Close > MiddleBandLine or CrossingUp (Sometime Not Large But More Time for TP From Intraday)
//          3.1.1.2) Can TP If Price Candle Breake UpperBandLine and Have a LightGreen Diamond "3Engulfing" or Have a Invert Arrow Direction
//      3.1.2) StopLoss (SL)
//          3.1.2.1) Can SL After Your Open Long/Buy Position by SwingLowLine
//  3.2) Bearish TP/SL
//      3.2.1) TakeProfit (TP)
//          3.2.1.1) Can TP If Close < MiddleBandLine or CrossingDown (Sometime Not Large But More Time for TP From Intraday)
//          3.2.1.2) Can TP If Price Candle Breake LowerBandLine and Have a LightRed Diamond "3Engulfing" or Have a Invert Arrow Direction
//      3.1.2) StopLoss (SL)
//          3.1.2.1) Can SL After Your Open Short/Sell Position by SwingHighLine

indicator("X48 - Indicator | Midnight Hunter | V.1.6", overlay = true, max_lines_count = 500, max_labels_count = 500,max_boxes_count = 500)

//INPUTS
var GRP1 = "== Midnight Hunter Band Setting =="
HalfLength = input.int(56, "Centered TMA Half Period", group = GRP1)
string PriceType = input.string("Weighted", "Price to use", options = ["Close", "Open", "High", "Low", "Median", "Typical", "Weighted", "Average"], group = GRP1)
AtrPeriod = input.int(110, "Average true range period", group = GRP1)
AtrMultiplier = input.float(2.5, "Average true range multiplier", group = GRP1)
TMAangle = input.int(4, "Centered TMA angle caution", group = GRP1)
tmawidth = input.int(defval = 1, title = 'Band LineWidth', minval = 1, maxval = 4, group = GRP1)

//Gold Hunter Setting : 56 , 110 , 2.5 , 4

//VARIABLES
float tmac = na
float tmau = na
float tmad = na

var float pastTmac = na //from the previous candle
var float pastTmau = na
var float pastTmad = na

float tmau_temp = na //before looping
float tmac_temp = na
float tmad_temp = na

float point = syminfo.pointvalue //NEEDS MORE TESTS

bool last = false //checks if a loop is needed

var string alertSignal = "EMPTY" //needed for alarms to avoid repetition

//COLORS
var GRP2 = "== Midnight Colors =="
var color colorBuffer = na
color colorDOWN = input.color(color.new(color.red, 0), "Bear Color", inline = "5", group = GRP1)
color colorUP = input.color(color.new(color.green, 0), "Bull Color", inline = "5", group = GRP1)
color colorBands = input.color(color.new(#b2b5be, 0), "3 Bands Color", inline = "5", group = GRP1)
bool cautionInput = input.bool(false, "Caution Label", inline = "6", group = GRP1)

//ALERTS
var GRP3 = "Alerts (Needs to create alert manually after every change)"
bool crossUpInput = input.bool(false, "Crossing up", inline = "7", group = GRP3)
bool crossDownInput = input.bool(false, "Crossing down", inline = "7", group = GRP3)
bool comingBackInput = input.bool(false, "Coming back", inline = "7", group = GRP3)
bool onArrowDownInput = input.bool(false, "On arrow down", inline = "8", group = GRP3)
bool onArrowUpInput = input.bool(false, "On arrow up", inline = "8", group = GRP3)

//CLEAR LINES
a_allLines = line.all
if array.size(a_allLines) > 0
    for p = 0 to array.size(a_allLines) - 1
        line.delete(array.get(a_allLines, p))
        
//GET PRICE        
Price(x) =>
    float price = switch PriceType
        "Close" => close[x]
        "Open" => open[x]
        "High" => high[x]
        "Low" => low[x]
        "Median" => (high[x] + low[x]) / 2
        "Typical" => (high[x] + low[x] + close[x]) / 3
        "Weighted" => (high[x] + low[x] + close[x] + close[x]) / 4
        "Average" => (high[x] + low[x] + close[x] + open[x])/ 4
    price

//MAIN
for i = HalfLength to 0

    //ATR
    atr = 0.0
    for j = 0 to  AtrPeriod - 1
        atr += math.max(high[i + j + 10], close[i + j + 11]) - math.min(low[i + j + 10], close[i + j + 11])
    atr /= AtrPeriod
    
    //BANDS
    sum = (HalfLength + 1) * Price(i)
    sumw = (HalfLength + 1)
    k = HalfLength
    for j = 1 to HalfLength
        sum += k * Price(i + j)
        sumw += k
        if (j <= i)
            sum  += k * Price(i - j)
            sumw += k
        k -= 1
    tmac := sum/sumw
    tmau := tmac+AtrMultiplier*atr
    tmad := tmac-AtrMultiplier*atr
    
    //ALERTS
    if i == 0 //Only on a real candle 
        if (high > tmau and alertSignal != "UP") //crossing up band
            if crossUpInput == true //checks if activated
                alert("Crossing up Band") //calling alert
            alertSignal := "UP" //to avoid repeating 
        else if (low < tmad and alertSignal != "DOWN") //crossing down band
            if crossDownInput == true
                alert("Crossing down Band")
            alertSignal := "DOWN"
        else if (alertSignal == "DOWN" and high >= tmad and alertSignal != "EMPTY") //back from the down band
            if comingBackInput == true
                alert("Coming back")
            alertSignal := "EMPTY"
        else if (alertSignal == "UP" and low <= tmau and alertSignal != "EMPTY") //back from the up band
            if comingBackInput == true
                alert("Coming back")
            alertSignal := "EMPTY"
            
    //CHANGE TREND COLOR
    if pastTmac != 0.0
        if tmac > pastTmac
            colorBuffer := colorUP
        if tmac < pastTmac
            colorBuffer := colorDOWN
            
    //SIGNALS
    reboundD = 0.0
    reboundU = 0.0
    caution = 0.0
    if pastTmac != 0.0
        if (high[i + 1] > pastTmau and close[i + 1] > open[i + 1] and close[i] < open[i])
            reboundD := high[i] + AtrMultiplier * atr / 2
            if (tmac - pastTmac > TMAangle * point)
                caution := reboundD + 10 * point
        if (low[i + 1] < pastTmad and close[i + 1] < open[i + 1] and close[i] > open[i])
            reboundU := low[i] - AtrMultiplier * atr / 2
            if (pastTmac - tmac > TMAangle * point)
                caution := reboundU - 10 * point
    
    //LAST REAL
    if barstate.islast and i == HalfLength
        last := true
        tmau_temp := tmau
        tmac_temp := tmac
        tmad_temp := tmad
        
    //DRAW HANDICAPPED BANDS
    if barstate.islast and i < HalfLength
        line.new(bar_index - (i + 1), pastTmau, bar_index - (i), tmau, width = 2, style = line.style_dotted, color = colorBands)
        line.new(bar_index - (i + 1), pastTmac, bar_index - (i), tmac, width = 2, style = line.style_dotted, color = colorBuffer)
        line.new(bar_index - (i + 1), pastTmad, bar_index - (i), tmad, width = 2, style = line.style_dotted, color = colorBands)
        
    //DRAW SIGNALS
    if reboundD != 0
        //label.new(bar_index - (i), reboundD, color = colorDOWN, style = label.style_triangledown, size = size.tiny, textcolor = na)
        label.new(bar_index - (i), reboundD, '▼', color = na, textcolor = colorDOWN, textalign=  text.align_center)
        if i == 0 and onArrowDownInput == true //alert
            alert("Down arrow") 
        if caution != 0 and cautionInput == true
            label.new(bar_index - (i), reboundD, color = colorUP, style = label.style_xcross, size = size.tiny, textcolor = na)
    if reboundU != 0
        //label.new(bar_index - (i), reboundU, color = colorUP, style = label.style_triangleup, size = size.tiny, textcolor = na)
        label.new(bar_index - (i), reboundU, '▲', color = na, textcolor = colorUP, textalign = text.align_center)
        if i == 0 and onArrowUpInput == true //alert
            alert("UP arrow") 
        if caution != 0 and cautionInput == true
            label.new(bar_index - (i), reboundU, color = colorDOWN, style = label.style_xcross, size = size.tiny, textcolor = na)
            
    //SAVE HISTORY
    pastTmac := tmac
    pastTmau := tmau
    pastTmad := tmad
    
    //LOOP IS ONLY FOR HANDICAPPED
    if barstate.islast != true
        break
        
//DRAW REAL BANDS
plot(last ? tmau_temp : tmau, title = "TMA Up", color = colorBands, linewidth=tmawidth, style = plot.style_line, offset = -HalfLength)
plot(last ? tmac_temp : tmac, title = "TMA Mid", color = colorBuffer, linewidth=tmawidth, style = plot.style_line, offset = -HalfLength)
plot(last ? tmad_temp : tmad, title = "TMA Down", color = colorBands, linewidth=tmawidth, style = plot.style_line, offset = -HalfLength)

threeengulfing_mode = input.bool(title="3 Candle Engulfing Signal", defval=true, group="== ENGULFING SIGNAL ==", inline = '9')
engulfing_mode = input.bool(title="Normal Engulfing Signal", defval=false, group="== ENGULFING SIGNAL ==", inline = '9')

// bullish engulfing (Bueng)
Bueng = open[3] > close[3] and open[2] > close[2] and open[1] > close[1] and close > open and (close >= open[1] or close[1] >= open) and close - open > open[1] - close[1]
plotshape(threeengulfing_mode ? Bueng : na, style=shape.diamond, location=location.belowbar, color=color.new(#00e926,0), size=size.small, text = "3Engulfing", textcolor = color.new(#4eff64,0))

// bearish engulfing (Beeng)
Beeng = open[3] < close[3] and open[2] < close[2] and close[1] > open[1] and open > close and (open >= close[1] or open[1] >= close) and open - close > close[1] - open[1]
plotshape(threeengulfing_mode ? Beeng : na, style=shape.diamond, location=location.abovebar, color=color.new(#ff571b,0), size=size.small, text = "3Engulfing", textcolor = color.new(#ff5a9b,0))

// bullish engulfing (Bueng)
Bueng2 = open[3] > close[3] ? open[2] > close[2] ? open[1] > close[1] ? close > open ? close >= open[1] ? close[1] >= open ? close - open > open[1] - close[1] ? color.blue : na : na : na : na : na : na : na
barcolor(threeengulfing_mode ? Bueng2 : na)

// bearish engulfing (Beeng)
Beeng2 = open[3] < close[3] ? open[2] < close[2] ? close[1] > open[1] ? open > close ? open >= close[1] ? open[1] >= close ? open - close > close[1] - open[1] ? color.white : na : na : na : na : na : na : na
barcolor(threeengulfing_mode ? Beeng2 : na)

////////////////////////////////////////////////////////////////////////////////////

/////////// Normal Setting ////////////////
srcstrategy = input(close, title='Source Multi MA', group = '= Multi MA SETTING =', tooltip = 'Normal Line = Close \nSmooth Line = ohlc4')

///////////// EMA/SMA SETTING /////////////
pricestrategy = request.security(syminfo.tickerid, timeframe.period, srcstrategy)
fastSW = input.bool(title='Show Fast MA Line', defval=false, group = '= Multi MA SETTING =', inline = '11')
fastcolor = input.color(color.new(color.red,0), group = '= Multi MA SETTING =', inline = '110', title = 'Fast MA Color')
slowSW = input.bool(title='Show Slow MA Line', defval=false, group = '= Multi MA SETTING =', inline = '11')
slowcolor = input.color(color.new(color.yellow,0), group = '= Multi MA SETTING =', inline = '110', title = 'Slow MA Color')
ma1strategy = input(18, title='Fast MA Length', group = '= Multi MA SETTING =', inline = '12')
type1strategy = input.string('EMA', 'Fast MA Type', options=['SMA', 'EMA', 'WMA', 'HMA', 'RMA', 'VWMA'], group = '= Multi MA SETTING =', tooltip = 'SMA / EMA / WMA / HMA / RMA / VWMA', inline = '12')

ma3strategy = input(34, title='Slow MA Length', group = '= Multi MA SETTING =', inline = '13')
type3strategy = input.string('EMA', 'Slow MA Type', options=['SMA', 'EMA', 'WMA', 'HMA', 'RMA', 'VWMA'], group = '= Multi MA SETTING =', tooltip = 'SMA / EMA / WMA / HMA / RMA / VWMA', inline = '13')

price1strategy = switch type1strategy
	"EMA" => ta.ema(pricestrategy, ma1strategy)
	"SMA" => ta.sma(pricestrategy, ma1strategy)
	"WMA" => ta.wma(pricestrategy, ma1strategy)
	"HMA" => ta.hma(pricestrategy, ma1strategy)
	"RMA" => ta.rma(pricestrategy, ma1strategy)
	"VWMA" => ta.vwma(pricestrategy, ma1strategy)
		
price3strategy = switch type3strategy
	"EMA" => ta.ema(pricestrategy, ma3strategy)
	"SMA" => ta.sma(pricestrategy, ma3strategy)
	"WMA" => ta.wma(pricestrategy, ma3strategy)
	"HMA" => ta.hma(pricestrategy, ma3strategy)
	"RMA" => ta.rma(pricestrategy, ma3strategy)
	"VWMA" => ta.vwma(pricestrategy, ma3strategy)

FastL = plot(fastSW ? price1strategy : na, 'Fast MA', color=fastcolor, style = plot.style_line, linewidth=2)
SlowL = plot(slowSW ? price3strategy : na, 'Slow MA', color=slowcolor, style = plot.style_line, linewidth=2)

///////////////////////////////////////////////////////////////////////////////////

stobg_mode = input.bool(title="Stochastic RSI Background Paint", defval=true, group="== STO BACKGROUND ==")
stobg_plot = input.bool(title="STO-TEXT", defval=false, group="== STO BACKGROUND ==", inline = 'STOT1')
stobull_text = input.color(title = 'BULL', defval = color.white, group = '== STO BACKGROUND ==', inline = 'STOT1')
stobear_text = input.color(title = 'BEAR', defval = color.orange, group = '== STO BACKGROUND ==', inline = 'STOT1')
lengthMACD = input(title='Length', defval=21, group = '== STO BACKGROUND ==', inline = '15')
offsetMACD = input(title='Offset', defval=0, group = '== STO BACKGROUND ==', inline = '15')
srcMACD = input(close, title='Source', group = '== STO BACKGROUND ==', inline = '16')
length2MACD = input(title='Trigger Length', defval=6, group = '== STO BACKGROUND ==', inline = '16')
bullstobg = input.color(title = 'Bull BG Color', defval = color.green, group = '== STO BACKGROUND ==', inline = 'STOBG1')
bearstobg = input.color(title = 'Bear BG Color', defval = color.red, group = '== STO BACKGROUND ==', inline = 'STOBG1')
transstobg = input.int(defval = 75, title = 'Trans', minval = 0, maxval = 100, group = '== STO BACKGROUND ==', inline = 'STOBG1')

lsma = ta.linreg(srcMACD, lengthMACD, offsetMACD)
lsma2 = ta.linreg(lsma, lengthMACD, offsetMACD)
b = lsma - lsma2
zlsma2 = lsma + b
trig2 = ta.sma(zlsma2, length2MACD)

c1 = zlsma2 > trig2 ? bullstobg : bearstobg
stobull = ta.crossover(zlsma2,trig2)
stobear = ta.crossunder(zlsma2, trig2)
plotshape(stobg_plot ? stobull : na, title = 'STO-BULL', text = 'STO-BULL', location = location.belowbar, textcolor = stobull_text, size = size.tiny)
plotshape(stobg_plot ? stobear : na, title = 'STO-BULL', text = 'STO-BEAR', location = location.abovebar, textcolor = stobear_text, size = size.tiny)

p1 = plot(stobg_mode ? zlsma2 : na, color=c1, linewidth=0)
p2 = plot(stobg_mode ? trig2 : na, color=c1, linewidth=0)
fill(p1, p2, color=color.new(c1,transp = transstobg))

// bullish engulfing
bullishEngulfing = open[1] > close[1] ? close > open ? close >= open[1] ? close[1] >= open ? close - open > open[1] - close[1] ? color.purple : na : na : na : na : na
barcolor(engulfing_mode ? bullishEngulfing : na)

// bearish engulfing
bearishEngulfing = close[1] > open[1] ? open > close ? open >= close[1] ? open[1] >= close ? open - close > close[1] - open[1] ? color.yellow : na : na : na : na : na
barcolor(engulfing_mode ? bearishEngulfing : na)

bullishEngulfing2 = (open[1] > close[1] and close > open and close >= open[1] and close[1] >= open and close - open > open[1] - close[1]) and (zlsma2 > trig2)
bearishEngulfing2 = (close[1] > open[1] and open > close and open >= close[1] and open[1] >= close and open - close > close[1] - open[1]) and (zlsma2 < trig2)
plotshape(engulfing_mode ? bullishEngulfing2 : na, style=shape.labelup, location=location.belowbar, color=color.yellow, size=size.auto, text = '↗️')
plotshape(engulfing_mode ? bearishEngulfing2 : na, style=shape.labeldown, location=location.abovebar, color=color.white, size=size.auto, text = '↘️')

//Termline = ta.sma(close,200)
//plot(Termline, "TermLine", color = color.white, linewidth = 2, style = plot.style_line)

ma_trend_mode = input.bool(title="Show MA LINE For Big Trend", defval=false, group="== BIG TREND ==")
srcstrategy_trend = input(close, title='SOURCE OF BIG TREND', group = '== BIG TREND ==', tooltip = 'Normal Line = Close \nSmooth Line = ohlc4')
type4strategy = input.string('SMA', 'BIG TREND Type', options=['SMA', 'EMA', 'WMA', 'HMA', 'RMA', 'VWMA'], group = '== BIG TREND ==', tooltip = 'SMA / EMA / WMA / HMA / RMA / VWMA', inline = '19')
ma_trend = input(defval = 200, title = "BIG TREND VALUE", group = '== BIG TREND ==', inline = '19')
death_mode = input.bool(title="Show SHORT-TERM MA LINE For DEATH CROSS and GOLDEN CROSS", defval=false, group="== BIG TREND ==")
deathstrategy = input.string('SMA', 'CROSS MA Type', options=['SMA', 'EMA', 'WMA', 'HMA', 'RMA', 'VWMA'], group = '== BIG TREND ==', tooltip = 'SMA / EMA / WMA / HMA / RMA / VWMA', inline = '21')
death_trend = input(defval = 50, title = "CROSS MA VALUE", group = '== BIG TREND ==', inline = '21')


matrend = switch type4strategy
	"EMA" => ta.ema(srcstrategy_trend, ma_trend)
	"SMA" => ta.sma(srcstrategy_trend, ma_trend)
	"WMA" => ta.wma(srcstrategy_trend, ma_trend)
	"HMA" => ta.hma(srcstrategy_trend, ma_trend)
	"RMA" => ta.rma(srcstrategy_trend, ma_trend)
	"VWMA" => ta.vwma(srcstrategy_trend, ma_trend)

deathtrend = switch deathstrategy
	"EMA" => ta.ema(srcstrategy_trend, death_trend)
	"SMA" => ta.sma(srcstrategy_trend, death_trend)
	"WMA" => ta.wma(srcstrategy_trend, death_trend)
	"HMA" => ta.hma(srcstrategy_trend, death_trend)
	"RMA" => ta.rma(srcstrategy_trend, death_trend)
	"VWMA" => ta.vwma(srcstrategy_trend, death_trend)

mycol = matrend > close ? color.white : color.blue
deathcol = deathtrend > matrend ? color.new(color.green,50) : color.new(color.red,50)
plot(ma_trend_mode ? matrend : na, "SMA-TREND",color=mycol,linewidth = 2)
plot(death_mode ? deathtrend : na, "DEATH-TREND",color=deathcol,linewidth = 1, style = plot.style_stepline_diamond)

// Swing Plot
//Swing_MODE = input.bool(title="PLOT SWING MODE", defval=true, group = '= SWING SETTING =', tooltip = 'If Mode On = Plot Swing High and Swing Low')
Swing_STOP = input.bool(title="SWING MODE", defval=true, group = '== SWING SETTING ==', tooltip = 'If Mode On = Use Stop Loss By Last Swing')
pvtLenL = input.int(6, minval=1, title='Length Left', group = '== SWING SETTING ==', inline = '23')
pvtLenR = input.int(6, minval=1, title='Length Right', group = '== SWING SETTING ==', inline = '23')
swhcolor = input.color(defval = color.maroon, title = 'HH Color', inline = 'SWC1', group = '== SWING SETTING ==')
swlcolor = input.color(defval = color.green, title = 'LL Color', inline = 'SWC1', group = '== SWING SETTING ==')
swhwidth = input.int(defval = 1, title = 'Width', minval = 0, maxval = 4, inline = 'SWC1', group = '== SWING SETTING ==')

// Get High and Low Pivot Points
pvthi_ = ta.pivothigh(high, pvtLenL, pvtLenR)
pvtlo_ = ta.pivotlow(low, pvtLenL, pvtLenR)

// Force Pivot completion before plotting.
Shunt = 1  //Wait for close before printing pivot? 1 for true 0 for flase
maxLvlLen = 0  //Maximum Extension Length
pvthi = pvthi_[Shunt]
pvtlo = pvtlo_[Shunt]

// Count How many candles for current Pivot Level, If new reset.
counthi = ta.barssince(not na(pvthi))
countlo = ta.barssince(not na(pvtlo))

pvthis = fixnan(pvthi)
pvtlos = fixnan(pvtlo)
hipc = ta.change(pvthis) != 0 ? na : swhcolor
lopc = ta.change(pvtlos) != 0 ? na : swlcolor

// Display Pivot lines
plot(Swing_STOP ? maxLvlLen == 0 or counthi < maxLvlLen ? pvthis : na : na, color=hipc, linewidth=swhwidth, offset=-pvtLenR - Shunt, title='Top Levels')
plot(Swing_STOP ? maxLvlLen == 0 or countlo < maxLvlLen ? pvtlos : na : na, color=lopc, linewidth=swhwidth, offset=-pvtLenR - Shunt, title='Bottom Levels')
plot(Swing_STOP ? maxLvlLen == 0 or counthi < maxLvlLen ? pvthis : na : na, color=hipc, linewidth=swhwidth, offset=0, title='Top Levels 2')
plot(Swing_STOP ? maxLvlLen == 0 or countlo < maxLvlLen ? pvtlos : na : na, color=lopc, linewidth=swhwidth, offset=0, title='Bottom Levels 2')

//////////////////////////////
// Standard practice declared input variables with i_ easier to identify
fvg_mode = input.bool(false, "Endable/Disable FVG MODE",group = "== FVG IMBALANCE SETTING ==")
i_tf = input.timeframe("D", "MTF Timeframe", group = "== FVG IMBALANCE SETTING ==", inline = 'FVGTF')
i_mtf = input.string(defval = "Current TF",group = "== FVG IMBALANCE SETTING ==", title = "MTF Options", options = ["Current TF", "Current + HTF", "HTF"], inline = 'FVGTF')
i_tfos = input.int(defval = 10,title = "Offset", minval = 0, maxval = 500 ,group = "== FVG IMBALANCE SETTING ==", inline = "OS")
i_mtfos = input.int(defval = 20,title = "MTF Offset", minval = 0, maxval = 500 ,group = "== FVG IMBALANCE SETTING ==", inline = "OS")
i_fillByMid = input.bool(false, "MidPoint Fill",group = "== FVG IMBALANCE SETTING ==", tooltip = "When enabled FVG is filled when midpoint is tested")
i_deleteonfill = input.bool(true, "Delete Old On Fill",group = "== FVG IMBALANCE SETTING ==")
i_labeltf = input.bool(false,"Label FVG Timeframe",group = "== FVG IMBALANCE SETTING ==")


i_bullishfvgcolor = input.color(color.new(color.green,70), "Bullish FVG", group = "== FVG IMBALANCE SETTING ==", inline = "BLFVG")
i_mtfbullishfvgcolor = input.color(color.new(color.lime,70), "MTF Bullish FVG", group = "== FVG IMBALANCE SETTING ==", inline = "BLFVG")
i_bearishfvgcolor = input.color(color.new(color.red,70), "Bearish FVG", group = "== FVG IMBALANCE SETTING ==", inline = "BRFVG")
i_mtfbearishfvgcolor = input.color(color.new(color.maroon,70), "MTF Bearish FVG", group = "== FVG IMBALANCE SETTING ==", inline = "BRFVG")
i_midPointColor = input.color(color.new(color.white,70), "MidPoint Color", group = "== FVG IMBALANCE SETTING ==")
i_textColor = input.color(color.white, "Text Color", group = "== FVG IMBALANCE SETTING ==")

// }

// ———————————————————— Global data {
//Using current bar data for HTF highs and lows instead of security to prevent future leaking
var htfH = open
var htfL = open

if close > htfH 
    htfH:= close
if close < htfL
    htfL := close

//Security Data, used for HTF Bar Data reference

sClose = request.security(syminfo.tickerid, i_tf, close[1], barmerge.gaps_off, barmerge.lookahead_on)
sHighP2 = request.security(syminfo.tickerid, i_tf, high[2], barmerge.gaps_off, barmerge.lookahead_on)
sLowP2 = request.security(syminfo.tickerid, i_tf, low[2], barmerge.gaps_off, barmerge.lookahead_on)
sOpen = request.security(syminfo.tickerid, i_tf, open[1], barmerge.gaps_off, barmerge.lookahead_on)
sBar = request.security(syminfo.tickerid, i_tf, bar_index, barmerge.gaps_off, barmerge.lookahead_on)

// }

//var keyword can be used to hold data in memory, with pinescript all data is lost including variables unless the var keyword is used to preserve this data
var bullishgapholder = array.new_box(0)
var bearishgapholder = array.new_box(0)
var bullishmidholder = array.new_line(0)
var bearishmidholder = array.new_line(0)
var bullishlabelholder = array.new_label(0)
var bearishlabelholder = array.new_label(0)
var transparentcolor = color.new(color.white,100)

// ———————————————————— Functions {

//function paramaters best declared with '_' this helps defer from variables in the function scope declaration and elsewhere e.g. close => _close
f_gapCreation(_upperlimit,_lowerlimit,_midlimit,_bar,_boxholder,_midholder,_labelholder,_boxcolor,_mtfboxcolor, _htf)=>
    timeholder = str.tostring(i_tf)
    offset = i_mtfos
    boxbgcolor = _mtfboxcolor
    if _htf == false
        timeholder := str.tostring(timeframe.period)
        offset := i_tfos
        boxbgcolor := _boxcolor
    if fvg_mode
        array.push(_boxholder,box.new(_bar,_upperlimit,_bar+1,_lowerlimit,border_color=transparentcolor,bgcolor = boxbgcolor, extend = extend.right))
    if i_fillByMid 
        array.push(_midholder,line.new(_bar,_midlimit,_bar+1,_midlimit,color = i_midPointColor, extend = extend.right))
    if i_labeltf
  
        array.push(_labelholder,label.new(_bar+ offset,_midlimit * 0.999, text = timeholder + " FVG", style =label.style_none, size = size.normal, textcolor = i_textColor))
        
//checks for gap between current candle and 2 previous candle e.g. low of current candle and high of the candle before last, this is the fair value gap.
f_gapLogic(_close,_high,_highp2,_low,_lowp2,_open,_bar,_htf)=>
    
    if _open > _close

        if _high - _lowp2 < 0
            
            upperlimit = _close - (_close - _lowp2 )
            lowerlimit = _close - (_close-_high)
            midlimit = (upperlimit + lowerlimit) / 2
            f_gapCreation(upperlimit,lowerlimit,midlimit,_bar,bullishgapholder,bullishmidholder,bullishlabelholder,i_bullishfvgcolor,i_mtfbullishfvgcolor,_htf)
          
    else
        
        if _low - _highp2 > 0 
            upperlimit = _close - (_close-_low)
            lowerlimit = _close- (_close - _highp2),
            midlimit = (upperlimit + lowerlimit) / 2
            f_gapCreation(upperlimit,lowerlimit,midlimit,_bar,bearishgapholder,bearishmidholder,bearishlabelholder,i_bearishfvgcolor,i_mtfbearishfvgcolor,_htf)
        
//Used to remove the gap from its relevant array as a result of it being filled.
f_gapDeletion(_currentgap,_i,_boxholder,_midholder,_labelholder)=>
   
    array.remove(_boxholder,_i)
    if i_fillByMid
        currentmid=array.get(_midholder,_i)
        array.remove(_midholder,_i)
       
        if i_deleteonfill
            line.delete(currentmid)
        else
            line.set_extend(currentmid, extend.none)
            line.set_x2(currentmid,bar_index)
    if i_deleteonfill
        box.delete(_currentgap)
        
    else
        box.set_extend(_currentgap,extend.none)
        box.set_right(_currentgap,bar_index)
    if i_labeltf
        currentlabel=array.get(_labelholder,_i)
        array.remove(_labelholder,_i)
        if i_deleteonfill
            label.delete(currentlabel)

//checks if gap has been filled either by 0.5 fill (i_fillByMid) or SHRINKS the gap to reflect the true value gap left.
f_gapCheck(_high,_low)=>

    if array.size(bullishgapholder) > 0

        for i = array.size(bullishgapholder)-1 to 0
            currentgap = array.get(bullishgapholder,i)
            currenttop = box.get_top(currentgap)
            if i_fillByMid 
                currentmid = array.get(bullishmidholder,i)
                currenttop := line.get_y1(currentmid)
            
                
            if _high >= currenttop
                f_gapDeletion(currentgap,i,bullishgapholder,bullishmidholder,bullishlabelholder)
            if _high > box.get_bottom(currentgap) and _high < box.get_top(currentgap)
               
                box.set_bottom(fvg_mode ? currentgap : na,_high)
       
    if array.size(bearishgapholder) > 0

        for i = array.size(bearishgapholder)-1 to 0
            currentgap = array.get(bearishgapholder,i)
            currentbottom = box.get_bottom(currentgap)
            if i_fillByMid 
                currentmid = array.get(bearishmidholder,i)
                currentbottom := line.get_y1(currentmid)           
            if _low <= currentbottom
                f_gapDeletion(currentgap,i,bearishgapholder,bearishmidholder,bearishlabelholder)
       
            if _low < box.get_top(currentgap) and _low > box.get_bottom(currentgap)
       
                box.set_top(fvg_mode ? currentgap : na,_low)      
                
                
// pine provided function to determine a new bar
is_newbar(res) =>
    t = time(res)
    not na(t) and (na(t[1]) or t > t[1])

if is_newbar(i_tf)
    htfH := open
    htfL := open

// }

// User Input, allow MTF data calculations
if is_newbar(i_tf) and (i_mtf == "Current + HTF" or i_mtf == "HTF")
    f_gapLogic(sClose, htfH, sHighP2, htfL, sLowP2, sOpen,bar_index,true)
    
// Use current Timeframe data to provide gap logic
if (i_mtf == "Current + HTF" or i_mtf == "Current TF")
    f_gapLogic(close[1],high,high[2],low,low[2],open[1],bar_index,false)

f_gapCheck(high,low)

//Dashboard_mode = input.bool(title="Show Dashboard", defval=true, group="= DASH BOARD =")
//Start dashboard
import jdehorty/EconomicCalendar/1 as calendar

// ---- Table Settings Start ----//
max    = 160    //Maximum Length
min    = 10     //Minimum Length

var GRP5 = "== DASH BOARD SETTING =="
var GRP6 = "== DASH BOARD INDICATOR SETTING =="
var GRP7 = "== DASH BOARD TABLE SETTING =="
// Input setting page start
dash_loc    = input.session("Bottom Right","Dashboard Posision"  ,["Top Right","Bottom Right","Top Left","Bottom Left", "Middle Right","Bottom Center"], group = GRP5, inline = 'DB1')
text_size   = input.session('Small',"Dashboard Size"  ,options=["Tiny","Small","Normal","Large"]  ,group=GRP5, inline =  'DB1')
cell_up     = input.color(color.green,'Up Cell Color'  ,group=GRP5, inline = 'DB2')
cell_dn     = input.color(color.red,'Down Cell Color'  ,group=GRP5, inline = 'DB2')
cell_Neut   = input.color(color.gray,'Nochange  Cell Color'  ,group=GRP5, inline = 'DB2')
row_col     = color.blue
col_col     = color.white
txt_col     = color.white
cell_transp = input.int(60,'Cell Transparency'  ,minval=0  ,maxval=100  ,group=GRP5)

Header_col  = color.rgb(35, 94, 255)
//MACDV color
cell_MACDV1 = color.teal
cell_MACDV2 = color.green
cell_MACDV3 = color.red
cell_MACDV4 = color.rgb(194, 179, 47)
cell_MACDV5 = color.green
cell_MACDV6 = color.red
cell_MACDV7 = color.rgb(204, 8, 24)
//Momentum color
cell_phase1 = color.green
cell_phase2 = color.teal
cell_phase3 = color.red
cell_phase4 = color.red
cell_phase5 = color.orange
cell_phase6 = color.green
// ---- Table Settings End ----}//

// ---- Indicators Show/Hide Settings Start ----//

showCls     = input.bool(defval=false, title="Price Close",     group=GRP7, inline = 'DBSHOW1')
showMA01    = input.bool(defval=false, title="MA01",            group=GRP7, inline = 'DBSHOW2')
showMA02    = input.bool(defval=false, title="MA02",            group=GRP7, inline = 'DBSHOW2')
showMACross = input.bool(defval=true, title="Trend",           group=GRP7, inline = 'DBSHOW2')
showRSI     = input.bool(defval=true, title="RSI ",            group=GRP7, inline = 'DBSHOW2')
showMACDV   = input.bool(defval=true, title="MACDV",           group=GRP7, inline = 'DBSHOW2')
showSignalV = input.bool(defval=false, title="SignalV",         group=GRP7, inline = 'DBSHOW4')
showMACDV_Status = input.bool(defval=true, title="Condition",  group=GRP7, inline = 'DBSHOW4')
showmomentum = input.bool(defval=false, title="Momentum",       group=GRP7, inline = 'DBSHOW4')

//---- MACD-V code start ----//
MACD_fast_length    = input(title="MACD-V Fast", defval=14, group=GRP6, inline = 'DBMACD1')
MACD_slow_length    = input(title="MACD-V Slow", defval=26, group=GRP6, inline = 'DBMACD1')
MACD_signal_length  = input.int(title="MACD-V Signal ",  minval = 1, maxval = 50, defval = 9, group=GRP6, inline = 'DBMACD2')
MACD_atr_length     = input(title="ATR", defval=26, group=GRP6, inline = 'DBMACD2')

// ---- Indicators Show/Hide Settings end ----}//


// ==================
// ==== Settings ====
// ==================


//------Seting Color Calender Economi------

color1 = color.red
color2 = color.orange
color3 = color.yellow
color4 = color.lime
color5 = color.aqua
color6 = color.fuchsia
color7 = color.silver


show_fomc_meetings = input.bool(defval = false, title = "📅 FOMC", inline = "FOMC", group="⚙️ Settings", tooltip="The FOMC meets eight times a year to determine the course of monetary policy. The FOMC's decisions are announced in a press release at 2:15 p.m. ET on the day of the meeting. The press release is followed by a press conference at 2:30 p.m. ET. The FOMC's decisions are based on a review of economic and financial developments and its assessment of the likely effects of these developments on the economic outlook.")
c_fomcMeeting = input.color(color.new(color1, 50), title = "Color", group="⚙️ Settings", inline = "FOMC")

show_fomc_minutes = input.bool(defval = false, title = "📅 FOMC Minutes", inline = "FOMCMinutes", group="⚙️ Settings", tooltip="The FOMC minutes are released three weeks after each FOMC meeting. The minutes provide a detailed account of the FOMC's discussion of economic and financial developments and its assessment of the likely effects of these developments on the economic outlook.")
c_fomcMinutes = input.color(color.new(color2, 50), title = "Color", group="⚙️ Settings", inline = "FOMCMinutes")

show_ppi = input.bool(defval = false, title = "📅 Producer Price Index (PPI)", inline = "PPI", group="⚙️ Settings", tooltip="The Producer Price Index (PPI) measures changes in the price level of goods and services sold by domestic producers. The PPI is a weighted average of prices of a basket of goods and services, such as transportation, food, and medical care. The PPI is a leading indicator of CPI.")
c_ppi = input.color(color.new(color3, 50), title = "Color", group="⚙️ Settings", inline = "PPI")

show_cpi = input.bool(defval = false, title = "📅 Consumer Price Index (CPI)", inline = "CPI", group="⚙️ Settings", tooltip="The Consumer Price Index (CPI) measures changes in the price level of goods and services purchased by households. The CPI is a weighted average of prices of a basket of consumer goods and services, such as transportation, food, and medical care. The CPI-U is the most widely used measure of inflation. The CPI-U is based on a sample of about 87,000 households and measures the change in the cost of a fixed market basket of goods and services purchased by urban consumers.")
c_cpi = input.color(color.new(color4, 50), title = "Color", group="⚙️ Settings", inline = "CPI")

show_csi = input.bool(defval = false, title = "📅 Consumer Sentiment Index (CSI)", inline = "CSI", group="⚙️ Settings", tooltip="The University of Michigan's Consumer Sentiment Index (CSI) is a measure of consumer attitudes about the economy. The CSI is based on a monthly survey of 500 U.S. households. The index is based on consumers' assessment of present and future economic conditions. The CSI is a leading indicator of consumer spending, which accounts for about two-thirds of U.S. economic activity.")
c_csi = input.color(color.new(color5, 50), title = "Color", group="⚙️ Settings", inline = "CSI")

show_cci = input.bool(defval = false, title = "📅 Consumer Confidence Index (CCI)", inline = "CCI", group="⚙️ Settings", tooltip="The Conference Board's Consumer Confidence Index (CCI) is a measure of consumer attitudes about the economy. The CCI is based on a monthly survey of 5,000 U.S. households. The index is based on consumers' assessment of present and future economic conditions. The CCI is a leading indicator of consumer spending, which accounts for about two-thirds of U.S. economic activity.")
c_cci = input.color(color.new(color6, 50), title = "Color", group="⚙️ Settings", inline = "CCI")

show_nfp = input.bool(defval = false, title = "📅 Non-Farm Payroll (NFP)", inline = "NFP", group="⚙️ Settings", tooltip="The Non-Farm Payroll (NFP) is a measure of the change in the number of employed persons, excluding farm workers and government employees. The NFP is a leading indicator of consumer spending, which accounts for about two-thirds of U.S. economic activity.")
c_nfp = input.color(color.new(color7, 50), title = "Color", group="⚙️ Settings", inline = "NFP")

show_legend = input.bool(false, "Show Legend", group="⚙️ Settings", inline = "Legend", tooltip="Show the color legend for the economic calendar events.")


// =======================
// ==== Dates & Times ====
// =======================

getUnixTime(_eventArr, _index) => 
    switch 
        timeframe.isdaily => array.get(_eventArr, _index) - timeframe.multiplier*86400000 // -n day(s)
        timeframe.isweekly => array.get(_eventArr, _index) - timeframe.multiplier*604800000 // -n week(s)
        timeframe.ismonthly => array.get(_eventArr, _index) - timeframe.multiplier*2592000000 // -n month(s)
        timeframe.isminutes and timeframe.multiplier > 59 => array.get(_eventArr, _index) - timeframe.multiplier*60000 // -n minute(s)
        => array.get(_eventArr, _index)

if barstate.islastconfirmedhistory

    // Note: An offset of -n units is needed to realign events with the timeframe in which they occurred
    if show_fomc_meetings
        fomcMeetingsArr = calendar.fomcMeetings()
        for i = 0 to array.size(fomcMeetingsArr) - 1
            unixTime = getUnixTime(fomcMeetingsArr, i)
            line.new(x1=unixTime, y1=high, x2=unixTime, y2=low, extend=extend.both,color=c_fomcMeeting, width=2, xloc=xloc.bar_time)

    if show_fomc_minutes
        fomcMinutesArr = calendar.fomcMinutes()
        for i = 0 to array.size(fomcMinutesArr) - 1
            unixTime = getUnixTime(fomcMinutesArr, i)
            line.new(x1=unixTime, y1=high, x2=unixTime, y2=low, extend=extend.both,color=c_fomcMinutes, width=2, xloc=xloc.bar_time)

    if show_ppi
        ppiArr = calendar.ppiReleases()
        for i = 0 to array.size(ppiArr) - 1
            unixTime = getUnixTime(ppiArr, i)
            line.new(x1=unixTime, y1=high, x2=unixTime, y2=low, extend=extend.both,color=c_ppi, width=2, xloc=xloc.bar_time)

    if show_cpi
        cpiArr = calendar.cpiReleases()
        for i = 0 to array.size(cpiArr) - 1
            unixTime = getUnixTime(cpiArr, i)
            line.new(x1=unixTime, y1=high, x2=unixTime, y2=low, extend=extend.both,color=c_cpi, width=2, xloc=xloc.bar_time)
    
    if show_csi
        csiArr = calendar.csiReleases()
        for i = 0 to array.size(csiArr) - 1
            unixTime = getUnixTime(csiArr, i)
            line.new(x1=unixTime, y1=high, x2=unixTime, y2=low, extend=extend.both,color=c_csi, width=2, xloc=xloc.bar_time)
    
    if show_cci
        cciArr = calendar.cciReleases()
        for i = 0 to array.size(cciArr) - 1
            unixTime = getUnixTime(cciArr, i)
            line.new(x1=unixTime, y1=high, x2=unixTime, y2=low, extend=extend.both,color=c_cci, width=2, xloc=xloc.bar_time)
    
    if show_nfp
        nfpArr = calendar.nfpReleases()
        for i = 0 to array.size(nfpArr) - 1
            unixTime = getUnixTime(nfpArr, i)
            line.new(x1=unixTime, y1=high, x2=unixTime, y2=low, extend=extend.both,color=c_nfp, width=2, xloc=xloc.bar_time)

// ================
// ==== Legend ====
// ================
if show_legend
    var tbl = table.new(position.top_right, columns=8, rows=8, frame_color=#151715, frame_width=1, border_width=2, border_color=color.new(color.black, 100))
    units = timeframe.isminutes ? "m" : ""
    table.cell(tbl, 1, 0, syminfo.ticker + ' => ' + str.tostring(timeframe.period)+ units, text_halign=text.align_center, text_color=color.gray, text_size=size.small)
    table.cell(tbl, 2, 0, 'FOMC Meeting', text_halign=text.align_center, bgcolor=color.black, text_color=color1, text_size=size.small)
    table.cell(tbl, 3, 0, 'FOMC Minutes', text_halign=text.align_center, bgcolor=color.black, text_color=color2, text_size=size.small)
    table.cell(tbl, 4, 0, 'Producer Price Index (PPI)', text_halign=text.align_center, bgcolor=color.black, text_color=color3, text_size=size.small)
    table.cell(tbl, 1, 1, 'Consumer Price Index (CPI)', text_halign=text.align_center, bgcolor=color.black, text_color=color4, text_size=size.small)
    table.cell(tbl, 2, 1, 'Consumer Sentiment Index (CSI)', text_halign=text.align_center, bgcolor=color.black, text_color=color5, text_size=size.small)
    table.cell(tbl, 3, 1, 'Consumer Confidence Index (CCI)', text_halign=text.align_center, bgcolor=color.black, text_color=color6, text_size=size.small)
    table.cell(tbl, 4, 1, 'Non-Farm Payrolls (NFP)', text_halign=text.align_center, bgcolor=color.black, text_color=color7, text_size=size.small)

// =======================
// ==== CE And ===========
// =======================


// ---- Timeframe Row Show/Hide Settings Start ----//
showTF1 = input.bool(defval=true, title="Show TF MN", inline='indicator1',group="Rows Settings")

f_MACDV(_close) =>

    //---- Indicators code Start ----//
    CLS= _close[1]

    //---- RSI code start ----//
    rsiPeriod   = 14
    RSI         = ta.rsi(_close, rsiPeriod)

    //---- RSI code end ----//

    //---- EMA 1 code start----//
    length_MA1 = input.int(title="MA1",defval=50, minval=1, inline = 'TFROW1')
    MA1        = ta.ema(_close, length_MA1)
    //plot(MA01, color=color.red, title="MA1")
    //---- EMA 1  code end ----//

    //---- EMA 2 code start---//
    length_MA2 = input.int(title="MA2",defval=200, minval=1, inline = 'TFROW1')
    MA2        = ta.ema(_close, length_MA2)
    //plot(MA02, color=color.blue, title="MA2")
    //---- EMA 2  code end ----//

    // Input seeting page end
    // Calculating 
    fast_ma =  ta.ema(_close, MACD_fast_length)
    slow_ma =  ta.ema(_close, MACD_slow_length)
    atr     =  ta.atr(MACD_atr_length)
    MACDV   = (((fast_ma - slow_ma)/atr)*100)//[( 12 bar EMA - 26 bar EMA) / ATR(26) ] * 100
    SignalV = ta.ema(MACDV, MACD_signal_length)
    //---- MACD-V code end ----//

    //---- Indicators code end ----//


    //-----Condition start
    stringmacdv     =(MACDV>150) ? "Wait Continue/Reversal" :(MACDV>50 and MACDV<150 and MACDV>SignalV ) ? "Buy G0" :(MACDV>50 and MACDV<150 and MACDV<SignalV ) ? "Buy Retest":(MACDV<50) and (MACDV>-50) ? "Sideway" :(MACDV<-50 and MACDV>-150 and MACDV>SignalV ) ? "Short go":(MACDV<-50 and MACDV>-150 and MACDV<SignalV ) ? "Short Retest":(MACDV<150) ? "Wait Continue/Reversal" :na
    //momentum
    stringmomentum  =(CLS>MA1 and CLS>MA2 and MA1<MA2) ? "Accumulation:Stop Sell - Setup Buy" :(CLS>MA1 and CLS>MA2 and MA1>MA2) ? "Runing Up: Buy Runing":(CLS<MA1 and CLS>MA2 and MA1>MA2) ? "Re-Acumulasi: Continue Up":(CLS<MA1 and CLS<MA2 and MA1>MA2) ? "Distribution: Stop Buy-Setup Short":(CLS<MA1 and CLS<MA2 and MA1<MA2) ? "Re-Distribusi: Continue Down":(CLS>MA1 and CLS<MA2 and MA1<MA2) ? "Accumulation-Distribusi: Don't Trade Wait Break":na
        
    //-----Condition end

    // Return values
    [CLS, MA1, MA2, RSI, MACDV, SignalV, stringmacdv, stringmomentum]

// ] -------- Alerts ----------------- [


//---- Table Position & Size code start {----//
var table_position = dash_loc == 'Bottom Right' ? position.bottom_right :
  dash_loc == 'Bottom Left' ? position.bottom_left :
  dash_loc == 'Middle Right' ? position.middle_right :
  dash_loc == 'Bottom Center' ? position.bottom_center :
  dash_loc == 'Top Left' ? position.top_right : position.bottom_right
  
var table_text_size = text_size == 'Normal' ? size.normal :
  text_size == 'Tiny' ? size.tiny :
  text_size == 'Small' ? size.small :
  text_size == 'Normal' ? size.normal : size.large

var t = table.new(table_position,15,math.abs(max-min)+2,
  frame_color   =color.new(#f1ff2a, 0),
  frame_width   =1,
  border_color  =color.new(#f1ff2a,0),
  border_width  =1)
//---- Table Position & Size code end ----//

// get values for table

[CLS_chart, MA1_chart, MA2_chart, RSI_chart, MACDV_chart, SignalV_chart, stringmacdv_chart, stringmomentum_chart] = f_MACDV(close)
[CLS_5_min, MA1_5_min, MA2_5_min, RSI_5_min, MACDV_5_min, SignalV_5_min, stringmacdv_5_min, stringmomentum_5_min] = request.security(syminfo.tickerid, "5", f_MACDV(close), lookahead=barmerge.lookahead_on)
[CLS_15_min, MA1_15_min, MA2_15_min, RSI_15_min, MACDV_15_min, SignalV_15_min, stringmacdv_15_min, stringmomentum_15_min] = request.security(syminfo.tickerid, "15", f_MACDV(close), lookahead=barmerge.lookahead_on)
[CLS_1_hour, MA1_1_hour, MA2_1_hour, RSI_1_hour, MACDV_1_hour, SignalV_1_hour, stringmacdv_1_hour, stringmomentum_1_hour] = request.security(syminfo.tickerid, "60", f_MACDV(close), lookahead=barmerge.lookahead_on)
[CLS_4_hour, MA1_4_hour, MA2_4_hour, RSI_4_hour, MACDV_4_hour, SignalV_4_hour, stringmacdv_4_hour, stringmomentum_4_hour] = request.security(syminfo.tickerid, "240", f_MACDV(close), lookahead=barmerge.lookahead_on)
[CLS_1_day, MA1_1_day, MA2_1_day, RSI_1_day, MACDV_1_day, SignalV_1_day, stringmacdv_1_day, stringmomentum_1_day] = request.security(syminfo.tickerid, "D", f_MACDV(close), lookahead=barmerge.lookahead_on)


//---- Table Column & Rows code start ----//
if (barstate.islast)
    //---- Table Main Column Headers code start ----//
    table.cell(t,1,1, 'TimeFrame',text_color=col_col,text_size=table_text_size,bgcolor=Header_col)
    if showCls
        table.cell(t,2,1,'L.Close',text_color=col_col,text_size=table_text_size,bgcolor=Header_col)
    if showMA01
        table.cell(t,3,1,'MA01',text_color=col_col,text_size=table_text_size,bgcolor=Header_col)
    if showMA02
        table.cell(t,4,1,'MA02',text_color=col_col,text_size=table_text_size,bgcolor=Header_col)
    if showMACross
        table.cell(t,5,1,'Trend',text_color=col_col,text_size=table_text_size,bgcolor=Header_col)
    if showRSI
        table.cell(t,6,1,'RSI',text_color=col_col,text_size=table_text_size,bgcolor=Header_col)
    if showMACDV
        table.cell(t,7,1,'MACDV',text_color=col_col,text_size=table_text_size,bgcolor=Header_col)
    if showSignalV
        table.cell(t,8,1,'SignalV',text_color=col_col,text_size=table_text_size,bgcolor=Header_col)
    if showMACDV_Status
        table.cell(t,9,1,'Condition',text_color=col_col,text_size=table_text_size,bgcolor=Header_col)
    if showmomentum
        table.cell(t,10,1,'Phase Market',text_color=col_col,text_size=table_text_size,bgcolor=Header_col)  

    //---- Table Main Column Headers code end ----//
 
    //---- Display data code start ----//

    //---------------------- Chart period ----------------------------------

    table.cell(t, 1, 2, "Chart",text_color=color.white,text_size=table_text_size, bgcolor=color.rgb(0, 68, 255))
    if  showCls
        table.cell(t,2,2, str.tostring(CLS_chart, '#.###'),text_color=color.new(CLS_chart >CLS_chart[2] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(CLS_chart >CLS_chart[2] ? cell_up : cell_dn ,cell_transp))
    if  showMA01
        table.cell(t,3,2, str.tostring(MA1_chart, '#.###'),text_color=color.new(MA1_chart >MA1_chart[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA1_chart >MA1_chart[1]  ? cell_up : cell_dn ,cell_transp))
    if  showMA02
        table.cell(t,4,2, str.tostring(MA2_chart, '#.###'),text_color=color.new(MA2_chart >MA2_chart[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA2_chart >MA2_chart[1] ? cell_up : cell_dn ,cell_transp))
    if  showMACross
        table.cell(t,5,2, MA1_chart > MA2_chart ? "Bullish" : "Bearish",text_color=color.new(MA1_chart > MA2_chart ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA1_chart > MA2_chart ? cell_up : cell_dn ,cell_transp))
    if  showRSI
        table.cell(t,6,2, str.tostring(RSI_chart, '#.###'),text_color=color.new(RSI_chart > 50 ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(RSI_chart > 50 ? cell_up : cell_dn ,cell_transp))
    if  showMACDV
        table.cell(t,7,2,str.tostring(MACDV_chart, '#.###'),text_color=color.new(MACDV_chart > MACDV_chart[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MACDV_chart > MACDV_chart[1] ? cell_up : cell_dn ,cell_transp))
    if  showSignalV
        table.cell(t,8,2,str.tostring(SignalV_chart, '#.###'),text_color=color.new(SignalV_chart > SignalV_chart[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(SignalV_chart> SignalV_chart[1] ? cell_up : cell_dn ,cell_transp))
    if  showMACDV_Status
        table.cell(t,9,2,stringmacdv_chart,text_color=color.rgb(0, 0, 0),text_size=table_text_size, bgcolor=color.new(MACDV_chart>50 ? cell_up :MACDV_chart<-50 ?  cell_dn:cell_MACDV4  ,cell_transp)) 
    if  showmomentum
        table.cell(t,10,2,stringmomentum_chart,text_color=color.rgb(2, 2, 2),text_size=table_text_size, bgcolor=color.new(CLS_chart>MA1_chart and CLS_chart>MA2_chart and MA1_chart<MA2_chart ? cell_phase1 : (CLS_chart>MA1_chart and CLS_chart>MA2_chart and MA1_chart>MA2_chart) ? cell_phase2 : (CLS_chart<MA1_chart and CLS_chart>MA2_chart and MA1_chart>MA2_chart) ?cell_phase3 :(CLS_chart<MA1_chart and CLS_chart<MA2_chart and MA1_chart>MA2_chart) ? cell_phase4:(CLS_chart<MA1_chart and CLS_chart<MA2_chart and MA1_chart<MA2_chart) ? cell_phase5:(CLS_chart>MA1_chart and CLS_chart<MA2_chart and MA1_chart<MA2_chart) ? cell_phase6:col_col,cell_transp))

 //   alert("\nRSI =(" + str.tostring(CLS_chart, '#.###') + ")\n Momentum = (" + str.tostring(stringmomentum_chart) +  ")\n Trend =("+ str.tostring(MA1_chart > MA2_chart ? "Bullish" : "Bearish")+").", alert.freq_once_per_bar_close)
       


//---------------------- 5 minute chart ----------------------------------

    table.cell(t,1,3, "5 minute",text_color=color.white,text_size=table_text_size, bgcolor=color.rgb(0, 68, 255))
    if  showCls
        table.cell(t,2,3, str.tostring(CLS_5_min, '#.###'),text_color=color.new(CLS_5_min >CLS_5_min[2] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(CLS_5_min >CLS_5_min[2] ? cell_up : cell_dn ,cell_transp))
    if  showMA01
        table.cell(t,3,3, str.tostring(MA1_5_min, '#.###'),text_color=color.new(MA1_5_min >MA1_5_min[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA1_5_min >MA1_5_min[1]  ? cell_up : cell_dn ,cell_transp))
    if  showMA02
        table.cell(t,4,3, str.tostring(MA2_5_min, '#.###'),text_color=color.new(MA2_5_min >MA2_5_min[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA2_5_min >MA2_5_min[1] ? cell_up : cell_dn ,cell_transp))
    if  showMACross
        table.cell(t,5,3, MA1_5_min > MA2_5_min ? "Bullish" : "Bearish",text_color=color.new(MA1_5_min > MA2_5_min ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA1_5_min > MA2_5_min ? cell_up : cell_dn ,cell_transp))
    if  showRSI
        table.cell(t,6,3, str.tostring(RSI_5_min, '#.###'),text_color=color.new(RSI_5_min > 50 ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(RSI_5_min > 50 ? cell_up : cell_dn ,cell_transp))
    if  showMACDV
        table.cell(t,7,3,str.tostring(MACDV_5_min, '#.###'),text_color=color.new(MACDV_5_min > MACDV_5_min[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MACDV_5_min > MACDV_5_min[1] ? cell_up : cell_dn ,cell_transp))
    if  showSignalV
        table.cell(t,8,3,str.tostring(SignalV_5_min, '#.###'),text_color=color.new(SignalV_5_min > SignalV_5_min[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(SignalV_5_min> SignalV_5_min[1] ? cell_up : cell_dn ,cell_transp))
    if  showMACDV_Status
        table.cell(t,9,3,stringmacdv_5_min,text_color=color.rgb(5, 5, 5),text_size=table_text_size, bgcolor=color.new(MACDV_5_min>50 ? cell_up :MACDV_5_min<-50 ?  cell_dn:cell_MACDV4  ,cell_transp)) 
    if  showmomentum
        table.cell(t,10,3,stringmomentum_5_min,text_color=color.rgb(5, 5, 5),text_size=table_text_size, bgcolor=color.new(CLS_5_min>MA1_5_min and CLS_5_min>MA2_5_min and MA1_5_min<MA2_5_min ? cell_phase1 : (CLS_5_min>MA1_5_min and CLS_5_min>MA2_5_min and MA1_5_min>MA2_5_min) ? cell_phase2 : (CLS_5_min<MA1_5_min and CLS_5_min>MA2_5_min and MA1_5_min>MA2_5_min) ?cell_phase3 :(CLS_5_min<MA1_5_min and CLS_5_min<MA2_5_min and MA1_5_min>MA2_5_min) ? cell_phase4:(CLS_5_min<MA1_5_min and CLS_5_min<MA2_5_min and MA1_5_min<MA2_5_min) ? cell_phase5:(CLS_5_min>MA1_5_min and CLS_5_min<MA2_5_min and MA1_5_min<MA2_5_min) ? cell_phase6:col_col,cell_transp))


       

//---------------------- 15 minute chart ----------------------------------

    table.cell(t,1,4, "15 minute",text_color=color.rgb(245, 243, 243),text_size=table_text_size, bgcolor=color.rgb(0, 68, 255))
    if  showCls
        table.cell(t,2,4, str.tostring(CLS_15_min, '#.###'),text_color=color.new(CLS_15_min >CLS_15_min[2] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(CLS_15_min >CLS_15_min[2] ? cell_up : cell_dn ,cell_transp))
    if  showMA01
        table.cell(t,3,4, str.tostring(MA1_15_min, '#.###'),text_color=color.new(MA1_15_min >MA1_15_min[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA1_15_min >MA1_15_min[1]  ? cell_up : cell_dn ,cell_transp))
    if  showMA02
        table.cell(t,4,4, str.tostring(MA2_15_min, '#.###'),text_color=color.new(MA2_15_min >MA2_15_min[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA2_15_min >MA2_15_min[1] ? cell_up : cell_dn ,cell_transp))
    if  showMACross
        table.cell(t,5,4, MA1_15_min > MA2_15_min ? "Bullish" : "Bearish",text_color=color.new(MA1_15_min > MA2_15_min ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA1_15_min > MA2_15_min ? cell_up : cell_dn ,cell_transp))
    if  showRSI
        table.cell(t,6,4, str.tostring(RSI_15_min, '#.###'),text_color=color.new(RSI_15_min > 50 ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(RSI_15_min > 50 ? cell_up : cell_dn ,cell_transp))
    if  showMACDV
        table.cell(t,7,4,str.tostring(MACDV_15_min, '#.###'),text_color=color.new(MACDV_15_min > MACDV_15_min[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MACDV_15_min > MACDV_15_min[1] ? cell_up : cell_dn ,cell_transp))
    if  showSignalV
        table.cell(t,8,4,str.tostring(SignalV_15_min, '#.###'),text_color=color.new(SignalV_15_min > SignalV_15_min[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(SignalV_15_min> SignalV_15_min[1] ? cell_up : cell_dn ,cell_transp))
    if  showMACDV_Status
        table.cell(t,9,4,stringmacdv_15_min,text_color=color.rgb(7, 7, 7),text_size=table_text_size, bgcolor=color.new(MACDV_15_min>50 ? cell_up :MACDV_15_min<-50 ?  cell_dn:cell_MACDV4  ,cell_transp)) 
    if  showmomentum
        table.cell(t,10,4,stringmomentum_15_min,text_color=color.rgb(7, 7, 7),text_size=table_text_size, bgcolor=color.new(CLS_15_min>MA1_15_min and CLS_15_min>MA2_15_min and MA1_15_min<MA2_15_min ? cell_phase1 : (CLS_15_min>MA1_15_min and CLS_15_min>MA2_15_min and MA1_15_min>MA2_15_min) ? cell_phase2 : (CLS_15_min<MA1_15_min and CLS_15_min>MA2_15_min and MA1_15_min>MA2_15_min) ?cell_phase3 :(CLS_15_min<MA1_15_min and CLS_15_min<MA2_15_min and MA1_15_min>MA2_15_min) ? cell_phase4:(CLS_15_min<MA1_15_min and CLS_15_min<MA2_15_min and MA1_15_min<MA2_15_min) ? cell_phase5:(CLS_15_min>MA1_15_min and CLS_15_min<MA2_15_min and MA1_15_min<MA2_15_min) ? cell_phase6:col_col,cell_transp))


//---------------------- 1 Hour chart ----------------------------------

    table.cell(t,1,6, "1 Hour",text_color=color.white,text_size=table_text_size, bgcolor=color.rgb(0, 68, 255))
    if  showCls
        table.cell(t,2,6, str.tostring(CLS_1_hour, '#.###'),text_color=color.new(CLS_1_hour >CLS_1_hour[2] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(CLS_1_hour >CLS_1_hour[2] ? cell_up : cell_dn ,cell_transp))
    if  showMA01
        table.cell(t,3,6, str.tostring(MA1_1_hour, '#.###'),text_color=color.new(MA1_1_hour >MA1_1_hour[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA1_1_hour >MA1_1_hour[1]  ? cell_up : cell_dn ,cell_transp))
    if  showMA02
        table.cell(t,4,6, str.tostring(MA2_1_hour, '#.###'),text_color=color.new(MA2_1_hour >MA2_1_hour[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA2_1_hour >MA2_1_hour[1] ? cell_up : cell_dn ,cell_transp))
    if  showMACross
        table.cell(t,5,6, MA1_1_hour > MA2_1_hour ? "Bullish" : "Bearish",text_color=color.new(MA1_1_hour > MA2_1_hour ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA1_1_hour > MA2_1_hour ? cell_up : cell_dn ,cell_transp))
    if  showRSI
        table.cell(t,6,6, str.tostring(RSI_1_hour, '#.###'),text_color=color.new(RSI_1_hour > 50 ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(RSI_1_hour > 50 ? cell_up : cell_dn ,cell_transp))
    if  showMACDV
        table.cell(t,7,6,str.tostring(MACDV_1_hour, '#.###'),text_color=color.new(MACDV_1_hour > MACDV_1_hour[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MACDV_1_hour > MACDV_1_hour[1] ? cell_up : cell_dn ,cell_transp))
    if  showSignalV
        table.cell(t,8,6,str.tostring(SignalV_1_hour, '#.###'),text_color=color.new(SignalV_1_hour > SignalV_1_hour[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(SignalV_1_hour> SignalV_1_hour[1] ? cell_up : cell_dn ,cell_transp))
    if  showMACDV_Status
        table.cell(t,9,6,stringmacdv_1_hour,text_color=color.rgb(7, 7, 7),text_size=table_text_size, bgcolor=color.new(MACDV_1_hour>50 ? cell_up :MACDV_1_hour<-50 ?  cell_dn:cell_MACDV4  ,cell_transp)) 
    if  showmomentum
        table.cell(t,10,6,stringmomentum_1_hour,text_color=color.rgb(8, 8, 8),text_size=table_text_size, bgcolor=color.new(CLS_1_hour>MA1_1_hour and CLS_1_hour>MA2_1_hour and MA1_1_hour<MA2_1_hour ? cell_phase1 : (CLS_1_hour>MA1_1_hour and CLS_1_hour>MA2_1_hour and MA1_1_hour>MA2_1_hour) ? cell_phase2 : (CLS_1_hour<MA1_1_hour and CLS_1_hour>MA2_1_hour and MA1_1_hour>MA2_1_hour) ?cell_phase3 :(CLS_1_hour<MA1_1_hour and CLS_1_hour<MA2_1_hour and MA1_1_hour>MA2_1_hour) ? cell_phase4:(CLS_1_hour<MA1_1_hour and CLS_1_hour<MA2_1_hour and MA1_1_hour<MA2_1_hour) ? cell_phase5:(CLS_1_hour>MA1_1_hour and CLS_1_hour<MA2_1_hour and MA1_1_hour<MA2_1_hour) ? cell_phase6:col_col,cell_transp))


//---------------------- 4 Hour chart ----------------------------------

    table.cell(t,1,7, "4 Hour",text_color=color.white,text_size=table_text_size, bgcolor=color.rgb(0, 68, 255))
    if  showCls
        table.cell(t,2,7, str.tostring(CLS_4_hour, '#.###'),text_color=color.new(CLS_4_hour >CLS_4_hour[2] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(CLS_4_hour >CLS_4_hour[2] ? cell_up : cell_dn ,cell_transp))
    if  showMA01
        table.cell(t,3,7, str.tostring(MA1_4_hour, '#.###'),text_color=color.new(MA1_4_hour >MA1_4_hour[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA1_4_hour >MA1_4_hour[1]  ? cell_up : cell_dn ,cell_transp))
    if  showMA02
        table.cell(t,4,7, str.tostring(MA2_4_hour, '#.###'),text_color=color.new(MA2_4_hour >MA2_4_hour[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA2_4_hour >MA2_4_hour[1] ? cell_up : cell_dn ,cell_transp))
    if  showMACross
        table.cell(t,5,7, MA1_4_hour > MA2_4_hour ? "Bullish" : "Bearish",text_color=color.new(MA1_4_hour > MA2_4_hour ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA1_4_hour > MA2_4_hour ? cell_up : cell_dn ,cell_transp))
    if  showRSI
        table.cell(t,6,7, str.tostring(RSI_4_hour, '#.###'),text_color=color.new(RSI_4_hour > 50 ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(RSI_4_hour > 50 ? cell_up : cell_dn ,cell_transp))
    if  showMACDV
        table.cell(t,7,7,str.tostring(MACDV_4_hour, '#.###'),text_color=color.new(MACDV_4_hour > MACDV_4_hour[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MACDV_4_hour > MACDV_4_hour[1] ? cell_up : cell_dn ,cell_transp))
    if  showSignalV
        table.cell(t,8,7,str.tostring(SignalV_4_hour, '#.###'),text_color=color.new(SignalV_4_hour > SignalV_4_hour[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(SignalV_4_hour> SignalV_4_hour[1] ? cell_up : cell_dn ,cell_transp))
    if  showMACDV_Status
        table.cell(t,9,7,stringmacdv_4_hour,text_color=color.rgb(7, 7, 7),text_size=table_text_size, bgcolor=color.new(MACDV_4_hour>50 ? cell_up :MACDV_4_hour<-50 ?  cell_dn:cell_MACDV4  ,cell_transp)) 
    if  showmomentum
        table.cell(t,10,7,stringmomentum_4_hour,text_color=color.rgb(7, 7, 7),text_size=table_text_size, bgcolor=color.new(CLS_4_hour>MA1_4_hour and CLS_4_hour>MA2_4_hour and MA1_4_hour<MA2_4_hour ? cell_phase1 : (CLS_4_hour>MA1_4_hour and CLS_4_hour>MA2_4_hour and MA1_4_hour>MA2_4_hour) ? cell_phase2 : (CLS_4_hour<MA1_4_hour and CLS_4_hour>MA2_4_hour and MA1_4_hour>MA2_4_hour) ?cell_phase3 :(CLS_4_hour<MA1_4_hour and CLS_4_hour<MA2_4_hour and MA1_4_hour>MA2_4_hour) ? cell_phase4:(CLS_4_hour<MA1_4_hour and CLS_4_hour<MA2_4_hour and MA1_4_hour<MA2_4_hour) ? cell_phase5:(CLS_4_hour>MA1_4_hour and CLS_4_hour<MA2_4_hour and MA1_4_hour<MA2_4_hour) ? cell_phase6:col_col,cell_transp))


//---------------------- 1 Day chart ----------------------------------

    table.cell(t,1,9, "1 Day",text_color=color.white,text_size=table_text_size, bgcolor=color.rgb(0, 68, 253))
    if  showCls
        table.cell(t,2,9, str.tostring(CLS_1_day, '#.###'),text_color=color.new(CLS_1_day >CLS_1_day[2] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(CLS_1_day >CLS_1_day[2] ? cell_up : cell_dn ,cell_transp))
    if  showMA01
        table.cell(t,3,9, str.tostring(MA1_1_day, '#.###'),text_color=color.new(MA1_1_day >MA1_1_day[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA1_1_day >MA1_1_day[1]  ? cell_up : cell_dn ,cell_transp))
    if  showMA02
        table.cell(t,4,9, str.tostring(MA2_1_day, '#.###'),text_color=color.new(MA2_1_day >MA2_1_day[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA2_1_day >MA2_1_day[1] ? cell_up : cell_dn ,cell_transp))
    if  showMACross
        table.cell(t,5,9, MA1_1_day > MA2_1_day ? "Bullish" : "Bearish",text_color=color.new(MA1_1_day > MA2_1_day ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MA1_1_day > MA2_1_day ? cell_up : cell_dn ,cell_transp))
    if  showRSI
        table.cell(t,6,9, str.tostring(RSI_1_day, '#.###'),text_color=color.new(RSI_1_day > 50 ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(RSI_1_day > 50 ? cell_up : cell_dn ,cell_transp))
    if  showMACDV
        table.cell(t,7,9,str.tostring(MACDV_1_day, '#.###'),text_color=color.new(MACDV_1_day > MACDV_1_day[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(MACDV_1_day > MACDV_1_day[1] ? cell_up : cell_dn ,cell_transp))
    if  showSignalV
        table.cell(t,8,9,str.tostring(SignalV_1_day, '#.###'),text_color=color.new(SignalV_1_day > SignalV_1_day[1] ? cell_up : cell_dn ,0),text_size=table_text_size, bgcolor=color.new(SignalV_1_day> SignalV_1_day[1] ? cell_up : cell_dn ,cell_transp))
    if  showMACDV_Status
        table.cell(t,9,9,stringmacdv_1_day,text_color=color.rgb(5, 5, 5),text_size=table_text_size, bgcolor=color.new(MACDV_1_day>50 ? cell_up :MACDV_1_day<-50 ?  cell_dn:cell_MACDV4  ,cell_transp)) 
    if  showmomentum
        table.cell(t,10,9,stringmomentum_1_day,text_color=color.rgb(7, 7, 7),text_size=table_text_size, bgcolor=color.new(CLS_1_day>MA1_1_day and CLS_1_day>MA2_1_day and MA1_1_day<MA2_1_day ? cell_phase1 : (CLS_1_day>MA1_1_day and CLS_1_day>MA2_1_day and MA1_1_day>MA2_1_day) ? cell_phase2 : (CLS_1_day<MA1_1_day and CLS_1_day>MA2_1_day and MA1_1_day>MA2_1_day) ?cell_phase3 :(CLS_1_day<MA1_1_day and CLS_1_day<MA2_1_day and MA1_1_day>MA2_1_day) ? cell_phase4:(CLS_1_day<MA1_1_day and CLS_1_day<MA2_1_day and MA1_1_day<MA2_1_day) ? cell_phase5:(CLS_1_day>MA1_1_day and CLS_1_day<MA2_1_day and MA1_1_day<MA2_1_day) ? cell_phase6:col_col,cell_transp))


//---- Display data code end ----//
//End dahs board

// **********************************************

Ichi_Mode = input.bool(title="Ichimoku CLOUD MODE", defval=false, group = '== ICHIMOKU SETTING ==')
tenkan_len  = input(9,'Tenkan          ',inline='tenkan', group = '== ICHIMOKU SETTING ==', tooltip = 'TENKAN = FAST SIGNAL')
tenkan_mult = input(2.,'',inline='tenkan', group = '== ICHIMOKU SETTING ==')

kijun_len   = input(26,'Kijun             ',inline='kijun', group = '== ICHIMOKU SETTING ==', tooltip = 'KIJUN = SLOW SIGNAL')
kijun_mult  = input(4.,'',inline='kijun', group = '== ICHIMOKU SETTING ==')

spanB_len   = input(52,'Senkou Span A/B ',inline='span', group = '== ICHIMOKU SETTING ==', tooltip = 'SENKOU = CLOUD SIGNAL')
spanB_mult  = input(6.,'',inline='span', group = '== ICHIMOKU SETTING ==')
cloudacolor = input.color(defval = color.new(color.orange,20), title = 'CLOUD-A', inline='span1', group = '== ICHIMOKU SETTING ==')
cloudbcolor = input.color(defval = color.new(color.purple,20), title = 'CLOUD-B', inline='span1', group = '== ICHIMOKU SETTING ==')

chi_color = input.color(defval = color.new(#73ecff,0), title = "Chikou-Color", group = '== ICHIMOKU SETTING ==', inline = 'CHIKOU')
offset      = input(26,'Chikou', group = '== ICHIMOKU SETTING ==', tooltip = 'CHIKOU = CANDLE LOOK BACK DEFAULT = 26', inline = 'CHIKOU')
//------------------------------------------------------------------------------
avg(src,length,mult)=>
    atr = ta.atr(length)*mult
    up = hl2 + atr
    dn = hl2 - atr
    upper = 0.,lower = 0.
    upper := src[1] < upper[1] ? math.min(up,upper[1]) : up
    lower := src[1] > lower[1] ? math.max(dn,lower[1]) : dn
    
    os = 0,max = 0.,min = 0.
    os := src > upper ? 1 : src < lower ? 0 : os[1]
    spt = os == 1 ? lower : upper
    max := ta.cross(src,spt) ? math.max(src,max[1]) : os == 1 ? math.max(src,max[1]) : spt
    min := ta.cross(src,spt) ? math.min(src,min[1]) : os == 0 ? math.min(src,min[1]) : spt
    math.avg(max,min)
//------------------------------------------------------------------------------
tenkan = avg(close,tenkan_len,tenkan_mult)
kijun = avg(close,kijun_len,kijun_mult)

senkouA = math.avg(kijun,tenkan)
senkouB = avg(close,spanB_len,spanB_mult)
//------------------------------------------------------------------------------
tenkan_css = color.white
kijun_css = #ff5d00

cloud_a = cloudacolor
cloud_b = cloudbcolor

chikou_css = color.new(#73ecff,20)

plot(Ichi_Mode ? tenkan : na,'Tenkan-Sen',tenkan_css,style = plot.style_stepline, linewidth = 2)
plot(Ichi_Mode ? kijun : na,'Kijun-Sen',kijun_css, style = plot.style_stepline, linewidth = 2)

plot(Ichi_Mode ? ta.crossover(tenkan,kijun) ? kijun : na : na,'Crossover',#2157f3,3,plot.style_circles)
plot(Ichi_Mode ? ta.crossunder(tenkan,kijun) ? kijun : na : na,'Crossunder',#ff5d00,3,plot.style_circles)

A = plot(Ichi_Mode ? senkouA : na,'Senkou Span A',na,offset=offset-1)
B = plot(Ichi_Mode ? senkouB : na,'Senkou Span B',na,offset=offset-1)
fill(A,B,senkouA > senkouB ? cloud_a : cloud_b)

plot(Ichi_Mode ? close : na,'Chikou',chi_color,offset=-offset+1, linewidth = 2)

////////////////////////////////////////////////////////////////////////////////////////

RSI_MODE = input.bool(title="RSI MODE", defval=false, group = '== RSI SETTING >> COMFIRM RSI BEFORE OPEN POSITION ==', tooltip = 'If Mode On = Use RSI Strategy With Long and Short\n >> RSI Confirm Before Open Position')
//if RSI_MODE == true
RSILength = input(14, title='RSI Length', group = '== RSI SETTING >> PLOT RSI SIGNAL OB OS ==')
OverBought = input(70, title='RSI OB', group = '== RSI SETTING >> PLOT RSI SIGNAL OB OS ==', inline = 'RSI1')
OverSold = input(30, title='RSI OS', group = '== RSI SETTING >> PLOT RSI SIGNAL OB OS ==', inline = 'RSI1')
vrsi = ta.rsi(srcstrategy, RSILength)
RSIUP = ta.crossover(vrsi, OverBought)
RSIDOWN = ta.crossunder(vrsi, OverSold)
plotshape(RSI_MODE ? RSIUP : na, title='RSIUP', text = 'OB', color=color.new(color.yellow, 100), style=shape.circle, location=location.belowbar, size=size.auto)  //plot for buy icon
plotshape(RSI_MODE ? RSIDOWN : na, title='RSIDOWN', text = 'OS', color=color.new(color.red, 100), style=shape.circle, location=location.abovebar, size=size.auto)  //plot for buy icon

////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
MACD_MODE_SIG= input.bool(title="MACD MODE = MACD Cross Signal", defval=false, group = '== MACD SETTING ==', tooltip = 'If Mode On = Use MACD Strategy for Signal When Cross Up and Cross Down')
//if MACD_MODE_SIG == true
MACDfastLength = input(12, title='MACD Fast', group = '== MACD SETTING ==', inline = 'MACDSIG1')
MACDslowlength = input(26, title='MACD Slow', group = '== MACD SETTING ==', inline = 'MACDSIG1')
MACDLength = input(18, title='MACD Length', group = '== MACD SETTING ==')
macdupcolor = input.color(defval = color.new(color.green,0), title = 'CROSS-UP', inline = 'MACDCO', group = '== MACD SETTING ==')
macddowncolor = input.color(defval = color.new(color.red,0), title = 'CROSS-DOWN', inline = 'MACDCO', group = '== MACD SETTING ==')
MACD = ta.ema(close, MACDfastLength) - ta.ema(close, MACDslowlength)
aMACD = ta.ema(MACD, MACDLength)
delta = MACD - aMACD
macdTPl = (ta.crossover(delta, 0))
macdTPs = (ta.crossunder(delta, 0))
plotshape(MACD_MODE_SIG ? macdTPl : na, title='macdTPl', text = '💎', color=macdupcolor, style=shape.circle, location=location.belowbar, size=size.auto)  //plot for buy icon
plotshape(MACD_MODE_SIG ? macdTPs : na, title='macdTPs', text = '💎', color=macddowncolor, style=shape.circle, location=location.abovebar, size=size.auto)  //plot for buy icon