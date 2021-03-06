define ["underscore", "markdown", "settings", "text!templates/partials.html"], (_, markdown, settings, html) ->
    el = $(html)
    user: _.template(el.find("script.user").text())
    quest_labels: _.template(el.find("script.quest-labels").text())
    edit_tools: _.template(el.find("script.edit-tools").text())
    quest_link: _.template(el.find("script.quest-link").text())
    watchers: _.template(el.find("script.watchers").text())
    markdown: markdown
    settings: settings

