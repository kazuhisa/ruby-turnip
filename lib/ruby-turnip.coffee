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

    # 現在行を取得
    row = atom.workspace.getActiveTextEditor().getCursorBufferPosition().row
    currentLine = atom.workspace.getActiveTextEditor().lineTextForBufferRow(row)

    # 対象文字列を取得
    target = currentLine.match(/(\S+)(\s+)(.+)/)[3]

    # タグを取得
    tags = []
    atom.workspace.getActiveTextEditor().scan /(@\S+)/g, ({matchText}) =>
      tags.unshift(matchText.replace(/^@/, ""))
    console.log(tags)

    # スコープのリストを作成
    scopeList = []
    promiseScope = atom.workspace.scan scopeRegexp, options, (match) ->
      for i, value of match.matches
        name = value.matchText.match(/steps_for\s+(.+)\s+do/)[1]
        scopeList.push({path: match.filePath, name: name.replace(/:/,""), lineNo: value.range[0][0]})

    # ステップのリストを作成
    stepList = []
    promiseStep = atom.workspace.scan stepRegexp, options, (match) ->
      for i, value of match.matches
        step = value.matchText.match(/step\s+(.+)\s+do/)[1]
        step = step.replace(/^'/g,'').replace(/^"/g,'').replace(/'$/g,'').replace(/"$/g,'')
        step = step.replace(/:.+?\s/g,".+\s")
        stepList.push({path: match.filePath, name: step, lineNo: value.range[0][0], scope: ""})

    # 2つのリスト作成を待つ
    Promise.all([promiseScope, promiseStep]).then =>
      # スコープの設定を行う
      # TODO: scopeListで回して、行番号以降を同じステップで塗り替える
      for i, scope of scopeList
        results = (step for step in stepList when step.path is scope.path && step.lineNo > scope.lineNo)
        for j, result of results
          result.scope = scope.name

      for i, step of stepList
        console.log step
