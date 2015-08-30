RubyTurnipView = require './ruby-turnip-view'
StepJumper = require './step-jumper'
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
    stepJumper = new StepJumper(@getTarget(), @getTags())
    result = stepJumper.jumpToStep()
    result.then (data) =>
      if data
        atom.workspace.open(data.path,{initialLine: data.lineNo}).done
