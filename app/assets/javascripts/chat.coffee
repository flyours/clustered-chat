msgform = -> $("#msgform")
createTopicForm = -> $("#topicform")
comment = -> $("#comment")
topicNameEl = -> $("#topicName")
confirmButton = -> $("#sendMessageButton")
createTopicButton = -> $("#createTopicButton")
subscribeButton = -> $(".subscribe")
conversation = -> $("#conversation #messages")
messages = -> $("#messages")
topics = -> $("#topics")
messageOnLeftTemplate = -> $("#message-on-left-template")
topicsOnLeftTemplate = -> $("#topics-on-left-template")

messageExists = ->
  comment().val().trim().length

topicNameEntered = ->
  topicNameEl().val().trim().length

changeConfirmButtonState = (disable) ->
  confirmButton().prop "disabled", disable

enableConfirmButton = ->
  changeConfirmButtonState(false)

disableConfirmButton = ->
  changeConfirmButtonState(true)

resetForm = ->
  comment().val("")

resetTopicForm = ->
  topicNameEl().val("")

niceScrolls = ->
  conversation().niceScroll
    background: "#eee"
    cursorcolor: "#ddd"
    cursorwidth: "10px"
    autohidemode: false
    horizrailenabled: false

init = ->
  disableConfirmButton()
  niceScrolls()

topicNames = {}
currentTopic = undefined

$ ->
  init()

  templateScript =
    messageOnLeft: messageOnLeftTemplate().html(),
    topicsOnLeft: topicsOnLeftTemplate().html()

  template =
    messageOnLeft: Handlebars.compile(templateScript.messageOnLeft),
    topicsOnLeft: Handlebars.compile(templateScript.topicsOnLeft)

  ws = new WebSocket $("body").data("ws-url")
  ws.onmessage = (event) ->
    message = JSON.parse event.data
    console.log(' >> msg')
    console.log(message)
    switch message.type
      when "message"
        messages().append(messageOnLeft(message.user, message.text))
        messages().scrollTop(messages().prop("scrollHeight"))
      when "topicName"
        topicNames[message.topicId] = message.topicName
        topics().append(topicsOnLeft(message.topicName, message.topicId))
        topics().scrollTop(topics().prop("scrollHeight"))
      else
        console.log(message)

  ws.onerror = (event) ->
    console.log "WS error: " + event

  ws.onclose = (event) ->
    console.log "WS closed: " + event.code + ": " + event.reason + " " + event

  window.onbeforeunload = ->
    ws.onclose = ->
    ws.close()

  msgform().submit (event) ->
    event.preventDefault()
    message = { type: "message", topic: currentTopic, msg: comment().val() }
    if messageExists()
      ws.send(JSON.stringify(message))
      resetForm()
      disableConfirmButton()

  createTopicForm().submit (event) ->
    event.preventDefault()
    message = topicNameEl().val()
    if topicNameEntered()
      ws.send(JSON.stringify(message))
      resetTopicForm()

  messageOnLeft = (u, m) ->
    template.messageOnLeft(messageInfo(u, m))

  topicsOnLeft = (topicName, topicId) ->
    template.topicsOnLeft(topicInfo(topicName, topicId))

  messageInfo = (user, message) ->
    user : user,
    message : message

  topicInfo = (topic, topicId) ->
    topicName: topic,
    topicId: topicId

  topics().on 'click', '.subscribe', (event) ->
    el = $(event.target)
    topicId = el.data("topic-id")
    topicName = topicNames[topicId]
    currentTopic = topicName
    message = {type: "subscribe", topic: topicName}
    ws.send(JSON.stringify(message))
    clearChat()

  clearChat = ->
    messages().html("")

  key_enter = 13

  comment().keyup (event) ->
    if messageExists()
      enableConfirmButton()
    else
      disableConfirmButton()
    if event.which is key_enter && !event.shiftKey
      event.preventDefault()
      if messageExists()
        msgform().submit()
