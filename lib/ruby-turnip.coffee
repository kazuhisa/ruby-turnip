RubyTurnipView = require './ruby-turnip-view'
{CompositeDisposable} = require 'atom'

module.exports = RubyTurnip =
  rubyTurnipView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @rubyTurnipView = new RubyTurnipView(state.rubyTurnipViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @rubyTurnipView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'ruby-turnip:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'ruby-turnip:jump-to-step': => @jumpToStep()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @rubyTurnipView.destroy()

  serialize: ->
    rubyTurnipViewState: @rubyTurnipView.serialize()

  toggle: ->
    console.log 'RubyTurnip was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

  onFulfilled: (data) ->
    console.log(data.valueOf())

  promiseDone: (done) ->
    console.log(done, 'done')

  promiseCancel: (cancel) ->
    console.log(cancel, 'cancel')

  # Get target strings
  getTarget: ->
    row = atom.workspace.getActiveTextEditor().getCursorBufferPosition().row
    currentLine = atom.workspace.getActiveTextEditor().lineTextForBufferRow(row)
    currentLine.match(/(\S+)(\s+)(.+)/)[3]

  # Get current page tags (ex. @user @company)
  getTags: ->
    tags = []
    atom.workspace.getActiveTextEditor().scan /(@\S+)/g, ({matchText}) =>
      tags.unshift(matchText.replace(/^@/, ""))
    tags.push("")
    tags

  jumpToStep: ->
    stepRegexp = /step\s+(.+)\s+do/
    scopeRegexp = /steps_for\s+(.+)\s+do/
    options = {paths: ["spec/steps/**/*.rb"]}
    target = @getTarget()
    tags = @getTags()

    # Create Scope list
    scopeList = []
    promiseScope = atom.workspace.scan scopeRegexp, options, (match) ->
      for i, value of match.matches
        name = value.matchText.match(/steps_for\s+(.+)\s+do/)[1]
        scopeList.push({path: match.filePath, name: name.replace(/:/,""), lineNo: value.range[0][0]})

    # Create Step list
    stepList = []
    promiseStep = atom.workspace.scan stepRegexp, options, (match) ->
      for i, value of match.matches
        step = value.matchText.match(/step\s+(.+)\s+do/)[1]
        step = step.replace(/^'/g,'').replace(/^"/g,'').replace(/'$/g,'').replace(/"$/g,'')
        step = step.replace(/:\S+?\s+?/g,"\\s*\\S+?\\s+")
        step = ///^#{step}$///
        stepList.push({path: match.filePath, step: step, lineNo: value.range[0][0], scope: ""})

    # Wait for Promise completed
    Promise.all([promiseScope, promiseStep]).then =>
      # Set Scope for stepList
      for i, scope of scopeList
        results = (step for step in stepList when step.path is scope.path && step.lineNo > scope.lineNo)
        for j, result of results
          result.scope = scope.name

      for tag in tags
        for step in stepList
          if step.scope is tag && target.match(step.step)
            atom.workspace.open(step.path,{initialLine: step.lineNo}).done
            return
