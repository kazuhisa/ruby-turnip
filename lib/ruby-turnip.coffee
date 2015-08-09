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

  jumpToStep: ->
    console.log 'jumpToStep!'
    stepRegexp = /step\s+(.+)\s+do/
    scopeRegexp = /steps_for\s+(.+)\s+do/
    options = {paths: ["spec/steps/**/*.rb"]}
    scopeList = []
    promise = atom.workspace.scan scopeRegexp, options, (match) ->
      for i, value of match.matches
        scopeList.push({path: match.filePath, name: value.matchText, lineNo: value.range[0][0]})

    promise.then =>
      for i, value of scopeList
        console.log value
