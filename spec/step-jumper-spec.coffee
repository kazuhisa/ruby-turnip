StepJumper = require '../lib/step-jumper'

describe "jumping", ->
  describe "No Scoped", ->
    it "no params step", ->
      waitsForPromise ->
        stepJumper = new StepJumper("show me the page",[""])
        result = stepJumper.jumpToStep()
        result.then (data) =>
          expect(data.path).toMatch("web_steps.rb")
          expect(data.lineNo).toBe(0)

    it "params with step", ->
      waitsForPromise ->
        stepJumper = new StepJumper("the name checkbox should not be checked",[""])
        result = stepJumper.jumpToStep()
        result.then (data) =>
          expect(data.path).toMatch("web_steps.rb")
          expect(data.lineNo).toBe(4)

  describe "With Scoped", ->
    it "no params step", ->
      waitsForPromise ->
        stepJumper = new StepJumper("show me the page",["user"])
        result = stepJumper.jumpToStep()
        result.then (data) =>
          expect(data.path).toMatch("user_steps.rb")
          expect(data.lineNo).toBe(1)
    it "params with step", ->
      waitsForPromise ->
        stepJumper = new StepJumper("the name checkbox should not be checked",["user"])
        result = stepJumper.jumpToStep()
        result.then (data) =>
          expect(data.path).toMatch("user_steps.rb")
          expect(data.lineNo).toBe(5)
