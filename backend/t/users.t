use lib 'lib';
use Play::Test;
use parent qw(Test::Class);

use Play::DB qw(db);

sub setup :Test(setup) {
    reset_db();
}

sub join_realm :Tests {
    db->users->add({ login => 'foo', realms => ['europe'] });

    like
        exception { db->users->join_realm('foo', 'unknown') },
        qr/Unknown realm 'unknown'/;

    db->users->join_realm('foo', 'asia');

    my $user = db->users->get_by_login('foo');
    cmp_deeply $user->{realms}, ['europe', 'asia'];
    cmp_deeply $user->{rp}, { europe => 0, asia => 0 };

    like
        exception { db->users->join_realm('foo', 'asia') },
        qr/unable to join/;

}

sub follow_realm :Tests {
    db->users->add({ login => 'foo', realms => ['europe'] });

    like
        exception { db->users->follow_realm('foo', 'unknown') },
        qr/Unknown realm 'unknown'/;

    db->users->follow_realm('foo', 'asia');

    my $user = db->users->get_by_login('foo');
    cmp_deeply $user->{realms}, ['europe'];
    cmp_deeply $user->{rp}, { europe => 0 };
    cmp_deeply $user->{fr}, ['asia'];

    like
        exception { db->users->follow_realm('foo', 'asia') },
        qr/unable to follow/;

}

sub unfollow_realm :Tests {
    db->users->add({ login => 'foo', realms => ['europe'] });

    like
        exception { db->users->unfollow_realm('foo', 'unknown') },
        qr/Unknown realm 'unknown'/;

    like
        exception { db->users->unfollow_realm('foo', 'asia') },
        qr/unable to unfollow/;

    db->users->follow_realm('foo', 'asia');
    db->users->unfollow_realm('foo', 'asia');

    like
        exception { db->users->unfollow_realm('foo', 'asia') },
        qr/unable to unfollow/;

    db->users->follow_realm('foo', 'asia');
    db->users->follow_realm('foo', 'europe');
    db->users->unfollow_realm('foo', 'asia');

    my $user = db->users->get_by_login('foo');
    cmp_deeply $user->{fr}, ['europe'];
}

sub follow_unfollow_user :Tests {
    db->users->add({ login => $_ }) for qw/ foo bar baz /;

    like
        exception { db->users->follow_user('foo', 'unknown') },
        qr/User 'unknown' not found/;

    db->users->follow_user('foo', 'bar');

    my $user = db->users->get_by_login('foo');
    cmp_deeply $user->{fu}, ['bar'];

    like
        exception { db->users->follow_user('foo', 'bar') },
        qr/unable to follow/;
    $user = db->users->get_by_login('foo');
    cmp_deeply $user->{fu}, ['bar'];

    db->users->follow_user('foo', 'baz');
    $user = db->users->get_by_login('foo');
    cmp_deeply $user->{fu}, ['bar', 'baz'];

    db->users->unfollow_user('foo', 'baz');
    $user = db->users->get_by_login('foo');
    cmp_deeply $user->{fu}, ['bar'];
}

sub unsubscribe :Tests {
    db->users->add({ login => 'foo', realms => ['europe'] });

    db->users->set_settings(foo => {
        email => 'test@example.com',
        notify_likes => 1,
        notify_comments => 1,
    });

    like exception {
        db->users->unsubscribe({
            login => 'foo',
            notify_field => 'notify_likes',
            secret => '123',
        })
    }, qr/secret key is wrong/, 'unsubscribe requires a secret key';

    is db->users->get_settings('foo')->{notify_likes}, 1, 'notify_likes is still on';

    my $secret = db->users->unsubscribe_secret('foo');
    db->users->unsubscribe({
        login => 'foo',
        notify_field => 'notify_likes',
        secret => $secret,
    });

    is db->users->get_settings('foo')->{notify_likes}, 0, 'notify_likes is off';
}

sub get_by_twitter_login :Tests {
    db->users->add({
        login => 'foo',
        twitter => { screen_name => 'tfoo', profile_image_url => 'http://example.com/foo/normal' },
        realms => ['europe'],
    });

    cmp_deeply
        scalar(db->users->get_by_twitter_login('tfoo')),
        superhashof({
            login => 'foo',
        });
}

sub settings :Tests {
    db->users->add({ login => 'foo' });
    cmp_deeply
        scalar(db->users->get_settings('foo')),
        {},
        'initial settings are empty';

    db->users->set_settings('foo', { blah => 5, duh => 6 });
    cmp_deeply
        scalar(db->users->get_settings('foo')),
        { blah => 5, duh => 6 },
        'set_settings can set multiple settings at once';

    db->users->set_settings('foo', { blah => 7 });
    cmp_deeply
        scalar(db->users->get_settings('foo')),
        { blah => 7 },
        'set_settings overwrites all settings';

    # TODO - test email and email_confirmed fields and $persona flag

    db->users->set_setting('foo', 'duh', 8);
    cmp_deeply
        scalar(db->users->get_settings('foo')),
        { blah => 7, duh => 8 },
        'set_setting updates settings';

    like
        exception {
            db->users->set_setting('foo', 'dum.dum', 9);
        },
        qr/Invalid setting name/;

    is
        exception {
            db->users->set_setting('foo', 'bum-bum', 10);
        },
        undef;

    cmp_deeply
        scalar(db->users->get_settings('foo')),
        { blah => 7, duh => 8, 'bum-bum' => 10 },
        'valid setting is set, invalid is not';
}

sub stat :Tests {
    db->users->add({ login => 'foo' });

    cmp_deeply
        db->users->stat('foo'),
        {
            quests => {
                open => 0,
                closed => 0,
                abandoned => 0,
            }
        };

    my @quests = map {
        db->quests->add({
            name => "q$_",
            user => 'foo',
            realm => 'europe',
        })
    } 1..10;

    db->quests->close($quests[$_]->{_id}, 'foo') for 1, 3, 5;
    db->quests->abandon($quests[$_]->{_id}, 'foo') for 2, 8;

    cmp_deeply
        db->users->stat('foo'),
        {
            quests => {
                open => 5,
                closed => 3,
                abandoned => 2,
            }
        }
}

__PACKAGE__->new->runtests;
