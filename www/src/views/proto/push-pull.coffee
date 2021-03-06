define ["underscore", "models/current-user", "views/proto/common"], (_, currentUser, Common) ->
    Common.extend
        buttonSelector: undefined
        ownerField: undefined
        field: undefined
        hidden: false
        push: ->

        pull: ->

        events:
            "click .push-self": "push"
            "click .pull-self": "pull"

        afterInitialize: ->
            @hidden = @options.hidden if @options.hidden?
            @listenTo @model, "change", @render

        showButton: ->
            @$(".like-button").removeClass "like-button-hide"
            @hidden = false

        hideButton: ->
            unless @list().length
                @$(".like-button").addClass "like-button-hide"
                @hidden = true

        list: ->
            @model.get(@field) or []

        serialize: ->
            currentLogin = currentUser.get("login")
            params =
                list: @list()
                currentUser: currentLogin

            params.my = @my(currentUser)
            params.meGusta = _.contains(params.list, currentLogin)
            params

        afterRender: ->
            @hideButton()  if @hidden

        features: ["tooltip"]


