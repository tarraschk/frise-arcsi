---
---
jQuery(document).ready ($) ->
  timelines = $('.cd-horizontal-timeline')
  eventsMinDistance = 120

  initTimeline = (timelines) ->
    timelines.each ->
      timeline = $(this)
      timelineComponents = {}
      #cache timeline components
      timelineComponents['timelineWrapper'] = timeline.find('.events-wrapper')
      timelineComponents['eventsWrapper'] = timelineComponents['timelineWrapper'].children('.events')
      timelineComponents['fillingLine'] = timelineComponents['eventsWrapper'].children('.filling-line')
      timelineComponents['timelineEvents'] = timelineComponents['eventsWrapper'].find('a')
      timelineComponents['timelineDates'] = parseDate(timelineComponents['timelineEvents'])
      timelineComponents['eventsMinLapse'] = minLapse(timelineComponents['timelineDates'])
      timelineComponents['timelineNavigation'] = timeline.find('.cd-timeline-navigation')
      timelineComponents['eventsContent'] = timeline.children('.events-content')
      #assign a left postion to the single events along the timeline
      setDatePosition timelineComponents, eventsMinDistance
      #assign a width to the timeline
      timelineTotWidth = setTimelineWidth(timelineComponents, eventsMinDistance)
      #the timeline has been initialize - show it
      timeline.addClass 'loaded'
      #detect click on the next arrow
      timelineComponents['timelineNavigation'].on 'click', '.next', (event) ->
        event.preventDefault()
        updateSlide timelineComponents, timelineTotWidth, 'next'
        return
      #detect click on the prev arrow
      timelineComponents['timelineNavigation'].on 'click', '.prev', (event) ->
        event.preventDefault()
        updateSlide timelineComponents, timelineTotWidth, 'prev'
        return
      #detect click on the a single event - show new event content
      timelineComponents['eventsWrapper'].on 'click', 'a', (event) ->
        event.preventDefault()
        timelineComponents['timelineEvents'].removeClass 'selected'
        $(this).addClass 'selected'
        updateOlderEvents $(this)
        updateFilling $(this), timelineComponents['fillingLine'], timelineTotWidth
        updateVisibleContent $(this), timelineComponents['eventsContent']
        return
      #on swipe, show next/prev event content
      timelineComponents['eventsContent'].on 'swipeleft', ->
        mq = checkMQ()
        mq == 'mobile' and showNewContent(timelineComponents, timelineTotWidth, 'next')
        return
      timelineComponents['eventsContent'].on 'swiperight', ->
        mq = checkMQ()
        mq == 'mobile' and showNewContent(timelineComponents, timelineTotWidth, 'prev')
        return
      #keyboard navigation
      $(document).keyup (event) ->
        if event.which == '37' and elementInViewport(timeline.get(0))
          showNewContent timelineComponents, timelineTotWidth, 'prev'
        else if event.which == '39' and elementInViewport(timeline.get(0))
          showNewContent timelineComponents, timelineTotWidth, 'next'
        return
      return
    return

  updateSlide = (timelineComponents, timelineTotWidth, string) ->
#retrieve translateX value of timelineComponents['eventsWrapper']
    translateValue = getTranslateValue(timelineComponents['eventsWrapper'])
    wrapperWidth = Number(timelineComponents['timelineWrapper'].css('width').replace('px', ''))
    #translate the timeline to the left('next')/right('prev')
    if string == 'next' then translateTimeline(timelineComponents, translateValue - wrapperWidth + eventsMinDistance, wrapperWidth - timelineTotWidth) else translateTimeline(timelineComponents, translateValue + wrapperWidth - eventsMinDistance)
    return

  showNewContent = (timelineComponents, timelineTotWidth, string) ->
#go from one event to the next/previous one
    visibleContent = timelineComponents['eventsContent'].find('.selected')
    newContent = if string == 'next' then visibleContent.next() else visibleContent.prev()
    if newContent.length > 0
#if there's a next/prev event - show it
      selectedDate = timelineComponents['eventsWrapper'].find('.selected')
      newEvent = if string == 'next' then selectedDate.parent('li').next('li').children('a') else selectedDate.parent('li').prev('li').children('a')
      updateFilling newEvent, timelineComponents['fillingLine'], timelineTotWidth
      updateVisibleContent newEvent, timelineComponents['eventsContent']
      newEvent.addClass 'selected'
      selectedDate.removeClass 'selected'
      updateOlderEvents newEvent
      updateTimelinePosition string, newEvent, timelineComponents
    return

  updateTimelinePosition = (string, event, timelineComponents) ->
#translate timeline to the left/right according to the position of the selected event
    eventStyle = window.getComputedStyle(event.get(0), null)
    eventLeft = Number(eventStyle.getPropertyValue('left').replace('px', ''))
    timelineWidth = Number(timelineComponents['timelineWrapper'].css('width').replace('px', ''))
    timelineTotWidth = Number(timelineComponents['eventsWrapper'].css('width').replace('px', ''))
    timelineTranslate = getTranslateValue(timelineComponents['eventsWrapper'])
    if string == 'next' and eventLeft > timelineWidth - timelineTranslate or string == 'prev' and eventLeft < -timelineTranslate
      translateTimeline timelineComponents, -eventLeft + timelineWidth / 2, timelineWidth - timelineTotWidth
    return

  translateTimeline = (timelineComponents, value, totWidth) ->
    eventsWrapper = timelineComponents['eventsWrapper'].get(0)
    value = if value > 0 then 0 else value
    #only negative translate value
    value = if !(typeof totWidth == 'undefined') and value < totWidth then totWidth else value
    #do not translate more than timeline width
    setTransformValue eventsWrapper, 'translateX', value + 'px'
    #update navigation arrows visibility
    if value == 0 then timelineComponents['timelineNavigation'].find('.prev').addClass('inactive') else timelineComponents['timelineNavigation'].find('.prev').removeClass('inactive')
    if value == totWidth then timelineComponents['timelineNavigation'].find('.next').addClass('inactive') else timelineComponents['timelineNavigation'].find('.next').removeClass('inactive')
    return

  updateFilling = (selectedEvent, filling, totWidth) ->
#change .filling-line length according to the selected event
    eventStyle = window.getComputedStyle(selectedEvent.get(0), null)
    eventLeft = eventStyle.getPropertyValue('left')
    eventWidth = eventStyle.getPropertyValue('width')
    eventLeft = Number(eventLeft.replace('px', '')) + Number(eventWidth.replace('px', '')) / 2
    scaleValue = eventLeft / totWidth
    setTransformValue filling.get(0), 'scaleX', scaleValue
    return

  setDatePosition = (timelineComponents, min) ->
    i = 0
    while i < timelineComponents['timelineDates'].length
      distance = daydiff(timelineComponents['timelineDates'][0], timelineComponents['timelineDates'][i])
      distanceNorm = Math.round(distance / timelineComponents['eventsMinLapse']) + 2
      timelineComponents['timelineEvents'].eq(i).css 'left', distanceNorm * min + 'px'
      i++
    return

  setTimelineWidth = (timelineComponents, width) ->
    `var timeSpanNorm`
    timeSpan = daydiff(timelineComponents['timelineDates'][0], timelineComponents['timelineDates'][timelineComponents['timelineDates'].length - 1])
    timeSpanNorm = timeSpan / timelineComponents['eventsMinLapse']
    timeSpanNorm = Math.round(timeSpanNorm) + 4
    totalWidth = timeSpanNorm * width
    timelineComponents['eventsWrapper'].css 'width', totalWidth + 'px'
    updateFilling timelineComponents['eventsWrapper'].find('a.selected'), timelineComponents['fillingLine'], totalWidth
    updateTimelinePosition 'next', timelineComponents['eventsWrapper'].find('a.selected'), timelineComponents
    totalWidth

  updateVisibleContent = (event, eventsContent) ->
    `var classEnetering`
    `var classLeaving`
    eventDate = event.data('date')
    visibleContent = eventsContent.find('.selected')
    selectedContent = eventsContent.find('[data-date="' + eventDate + '"]')
    selectedContentHeight = selectedContent.height()
    if selectedContent.index() > visibleContent.index()
      classEnetering = 'selected enter-right'
      classLeaving = 'leave-left'
    else
      classEnetering = 'selected enter-left'
      classLeaving = 'leave-right'
    selectedContent.attr 'class', classEnetering
    visibleContent.attr('class', classLeaving).one 'webkitAnimationEnd oanimationend msAnimationEnd animationend', ->
      visibleContent.removeClass 'leave-right leave-left'
      selectedContent.removeClass 'enter-left enter-right'
      return
    eventsContent.css 'height', selectedContentHeight + 'px'
    return

  updateOlderEvents = (event) ->
    event.parent('li').prevAll('li').children('a').addClass('older-event').end().end().nextAll('li').children('a').removeClass 'older-event'
    return

  getTranslateValue = (timeline) ->
    `var timelineTranslate`
    `var translateValue`
    timelineStyle = window.getComputedStyle(timeline.get(0), null)
    timelineTranslate = timelineStyle.getPropertyValue('-webkit-transform') or timelineStyle.getPropertyValue('-moz-transform') or timelineStyle.getPropertyValue('-ms-transform') or timelineStyle.getPropertyValue('-o-transform') or timelineStyle.getPropertyValue('transform')
    if timelineTranslate.indexOf('(') >= 0
      timelineTranslate = timelineTranslate.split('(')[1]
      timelineTranslate = timelineTranslate.split(')')[0]
      timelineTranslate = timelineTranslate.split(',')
      translateValue = timelineTranslate[4]
    else
      translateValue = 0
    Number translateValue

  setTransformValue = (element, property, value) ->
    element.style['-webkit-transform'] = property + '(' + value + ')'
    element.style['-moz-transform'] = property + '(' + value + ')'
    element.style['-ms-transform'] = property + '(' + value + ')'
    element.style['-o-transform'] = property + '(' + value + ')'
    element.style['transform'] = property + '(' + value + ')'
    return

  #based on http://stackoverflow.com/questions/542938/how-do-i-get-the-number-of-days-between-two-dates-in-javascript

  parseDate = (events) ->
    dateArrays = []
    events.each ->
      `var dayComp`
      `var timeComp`
      `var dayComp`
      `var timeComp`
      singleDate = $(this)
      dateComp = singleDate.data('date').split('T')
      if dateComp.length > 1
#both DD/MM/YEAR and time are provided
        dayComp = dateComp[0].split('/')
        timeComp = dateComp[1].split(':')
      else if dateComp[0].indexOf(':') >= 0
#only time is provide
        dayComp = [
          '2000'
          '0'
          '0'
        ]
        timeComp = dateComp[0].split(':')
      else
#only DD/MM/YEAR
        dayComp = dateComp[0].split('/')
        timeComp = [
          '0'
          '0'
        ]
      newDate = new Date(dayComp[2], dayComp[1] - 1, dayComp[0], timeComp[0], timeComp[1])
      dateArrays.push newDate
      return
    dateArrays

  daydiff = (first, second) ->
    Math.round second - first

  minLapse = (dates) ->
#determine the minimum distance among events
    dateDistances = []
    i = 1
    while i < dates.length
      distance = daydiff(dates[i - 1], dates[i])
      dateDistances.push distance
      i++
    Math.min.apply null, dateDistances

  ###
  	How to tell if a DOM element is visible in the current viewport?
  	http://stackoverflow.com/questions/123999/how-to-tell-if-a-dom-element-is-visible-in-the-current-viewport
  ###

  elementInViewport = (el) ->
    top = el.offsetTop
    left = el.offsetLeft
    width = el.offsetWidth
    height = el.offsetHeight
    while el.offsetParent
      el = el.offsetParent
      top += el.offsetTop
      left += el.offsetLeft
    top < window.pageYOffset + window.innerHeight and left < window.pageXOffset + window.innerWidth and top + height > window.pageYOffset and left + width > window.pageXOffset

  checkMQ = ->
#check if mobile or desktop device
    window.getComputedStyle(document.querySelector('.cd-horizontal-timeline'), '::before').getPropertyValue('content').replace(/'/g, '').replace /"/g, ''

  timelines.length > 0 and initTimeline(timelines)
  return

# ---
# generated by js2coffee 2.2.0