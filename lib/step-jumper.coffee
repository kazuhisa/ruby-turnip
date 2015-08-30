module.exports =
  class StepJumper
    constructor: (target, tags) ->
      @target = target
      @tags = tags

    jumpToStep: ->
      stepRegexp = /step\s+(.+)\s+do/
      scopeRegexp = /steps_for\s+(.+)\s+do/
      options = {paths: ["spec/steps/**/*.rb"]}

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

        for tag in @tags
          for step in stepList
            if step.scope is tag && @target.match(step.step)
              result = {path: step.path, lineNo: step.lineNo}
              return Promise.resolve(result)
        return Promise.resolve(null)
