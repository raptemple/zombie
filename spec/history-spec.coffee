require("./helpers")
{ vows: vows, assert: assert, zombie: zombie, brains: brains } = require("vows")
jsdom = require("jsdom")


brains.get "/boo", (req, res)->
  res.send "<html><title>Eeek!</title></html>"


vows.describe("History").addBatch({
  "new window":
    topic: -> new zombie.Browser().window
    "should start out empty": (window)-> assert.length window.history, 0
    "should start out with no location": (window)-> assert.isUndefined window.location.href
    "go forward":
      topic: (window)->
        window.history.forward()
        window
      "should have no effect": (window)->
        assert.length window.history, 0
        assert.isUndefined window.location.href
    "go backwards":
      topic: (window)->
        window.history.back()
        window
      "should have no effect": (window)->
        assert.length window.history, 0
        assert.isUndefined window.location.href

  "history":
    "pushState":
      zombie.wants "http://localhost:3003/"
        ready: (browser)->
          browser.window.history.pushState { is: "start" }, null, "/start"
          browser.window.history.pushState { is: "end" }, null, "/end"
          @callback null, browser.window
        "should add state to history": (window)-> assert.length window.history, 3
        "should change location URL": (window)-> assert.equal window.location.href, "/end"
        "go backwards":
          topic: (browser)->
            browser.window.addEventListener "popstate", (evt)=> @callback(null, evt)
            browser.window.history.back()
          "should fire popstate event": (evt)-> assert.instanceOf evt, jsdom.dom.level3.events.Event
          "should include state": (evt)-> assert.equal evt.state.is, "start"
        "go forwards":
          zombie.wants "http://localhost:3003/"
            ready: (browser)->
              browser.window.history.pushState { is: "start" }, null, "/start"
              browser.window.history.pushState { is: "end" }, null, "/end"
              browser.window.history.back()
              browser.window.addEventListener "popstate", (evt)=> @callback(null, evt)
              browser.window.history.forward()
            "should fire popstate event": (evt)-> assert.instanceOf evt, jsdom.dom.level3.events.Event
            "should include state": (evt)-> assert.equal evt.state.is, "end"
    "replaceState":
      zombie.wants "http://localhost:3003/"
        ready: (browser)->
          browser.window.history.pushState { is: "start" }, null, "/start"
          browser.window.history.replaceState { is: "end" }, null, "/end"
          @callback null, browser.window
        "should not add state to history": (window)-> assert.length window.history, 2
        "should change location URL": (window)-> assert.equal window.location.href, "/end"
        "go backwards":
          topic: (browser)->
            browser.window.addEventListener "popstate", (evt)=>
              browser.window.popstate = true
            browser.window.history.back()
            @callback null, browser.window
          "should change location URL": (window)-> assert.equal window.location.href, "http://localhost:3003/"
          "should not fire popstate event": (window)-> assert.isUndefined window.popstate

  "location":
    "open page":
      zombie.wants "http://localhost:3003/"
        "should add page to history": (browser)-> assert.length browser.window.history, 1
        "should change location URL": (browser)-> assert.equal browser.location, "http://localhost:3003/"
        "should load document": (browser)-> assert.match browser.html, /Tap, Tap/
    "change location":
      zombie.wants "http://localhost:3003/"
        ready: (browser)->
          browser.window.location = "http://localhost:3003/boo"
          browser.window.document.addEventListener "DOMContentLoaded", => @callback null, browser
        "should add page to history": (browser)-> assert.length browser.window.history, 2
        "should change location URL": (browser)-> assert.equal browser.location, "http://localhost:3003/boo"
        "should load document": (browser)-> assert.match browser.html, /Eeek!/
    "change pathname":
      zombie.wants "http://localhost:3003/"
        ready: (browser)->
          browser.window.location.pathname = "/boo"
          browser.window.document.addEventListener "DOMContentLoaded", => @callback null, browser
        "should add page to history": (browser)-> assert.length browser.window.history, 2
        "should change location URL": (browser)-> assert.equal browser.location, "http://localhost:3003/boo"
        "should load document": (browser)-> assert.match browser.html, /Eeek!/
    "change hash":
      zombie.wants "http://localhost:3003/"
        ready: (browser)->
          browser.window.document.innerHTML = "Wolf"
          browser.window.addEventListener "hashchange", => @callback null, browser
          browser.window.location.hash = "boo"
        "should add page to history": (browser)-> assert.length browser.window.history, 2
        "should change location URL": (browser)-> assert.equal browser.location, "http://localhost:3003/#boo"
        "should not reload document": (browser)-> assert.match browser.document.innerHTML, /Wolf/
    "assign":
      zombie.wants "http://localhost:3003/"
        ready: (browser)->
          browser.window.location.assign "http://localhost:3003/boo"
          browser.document.addEventListener "DOMContentLoaded", => @callback null, browser
        "should add page to history": (browser)-> assert.length browser.window.history, 2
        "should change location URL": (browser)-> assert.equal browser.location, "http://localhost:3003/boo"
        "should load document": (browser)-> assert.match browser.html, /Eeek!/
    "replace":
      zombie.wants "http://localhost:3003/"
        ready: (browser)->
          browser.window.location.replace "http://localhost:3003/boo"
          browser.window.document.addEventListener "DOMContentLoaded", => @callback null, browser
        "should not add page to history": (browser)-> assert.length browser.window.history, 1
        "should change location URL": (browser)-> assert.equal browser.location, "http://localhost:3003/boo"
        "should load document": (browser)-> assert.match browser.html, /Eeek!/
    "reload":
      zombie.wants "http://localhost:3003/"
        ready: (browser)->
          browser.window.document.innerHTML = "Wolf"
          browser.window.location.reload()
          browser.window.document.addEventListener "DOMContentLoaded", => @callback null, browser
        "should not add page to history": (browser)-> assert.length browser.window.history, 1
        "should not change location URL": (browser)-> assert.equal browser.location, "http://localhost:3003/"
        "should reload document": (browser)-> assert.match browser.html, /Tap, Tap/
}).export(module);
