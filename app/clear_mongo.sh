#!/bin/sh

# TODO - remove 'quest.user' index when migration on quest.team will be over

CODE=$(cat <<END
use play
db.quests.drop()
db.users.drop()
db.sessions.drop()
db.comments.drop()
db.events.drop()
db.users.ensureIndex({ "login": 1 }, { "unique": 1 })
db.users.ensureIndex({ "twitter.login": 1 }, { "unique": 1 })
db.users.ensureIndex({ "settings.email": 1 }, { "unique": 1 })
db.quests.ensureIndex({ "tags": 1 })
db.quests.ensureIndex({ "user": 1 })
db.quests.ensureIndex({ "team": 1 })
END
)

(echo 'use play'; echo "$CODE") | mongo
(echo 'use play_test'; echo "$CODE") | mongo
