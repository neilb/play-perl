#!/usr/bin/perl

use lib 'lib';
use Play::Test;
use parent qw(Test::Class);

use Play::DB qw(db);

sub setup :Test(setup) {
    reset_db();
}

sub _cmp_list {
    my ($query, $types) = @_;

    cmp_deeply(
        db->events->list($query),
        [ map { superhashof({ type => $_ }) } @$types ]
    );
}

sub list_realm :Tests {
    db->users->add({ login => 'foo' });
    db->users->add({ login => 'bar' });

    db->events->add({
        type => 'e1',
        author => 'foo',
        realm => 'europe',
    });
    db->events->add({
        type => 'e2',
        author => 'bar',
        realm => 'europe',
    });
    db->events->add({
        type => 'e3',
        author => 'bar',
        realm => 'asia',
    });

    _cmp_list
        { realm => 'europe' },
        [qw( e2 e1 )];
}

sub list_for_self :Tests {
    db->users->add({ login => 'foo' });
    db->users->add({ login => 'bar' });

    db->events->add({
        type => 'e1',
        author => 'foo',
        realm => 'europe',
    });
    db->events->add({
        type => 'e2',
        author => 'foo',
        realm => 'europe',
    });
    db->events->add({
        type => 'e3',
        author => 'bar',
        realm => 'europe',
    });

    _cmp_list
        { for => 'foo' },
        [qw( e2 e1 )];
}

sub list_for_fr :Tests {
    db->users->add({ login => 'foo', fr => ['asia'] });
    db->users->add({ login => 'bar' });
    db->users->add({ login => 'baz', fr => ['asia', 'europe'] });

    db->events->add({
        type => 'e1',
        author => 'bar',
        realm => 'europe',
    });
    db->events->add({
        type => 'e2',
        author => 'bar',
        realm => 'asia',
    });
    db->events->add({
        type => 'e3',
        author => 'bar',
        realm => 'asia',
    });

    _cmp_list
        { for => 'foo' },
        [qw( e3 e2 )];
    _cmp_list
        { for => 'baz' },
        [qw( e3 e2 e1 )];
}

sub list_for_fu :Tests {
    db->users->add({ login => 'foo', fu => ['bar'] });
    db->users->add({ login => 'bar' });
    db->users->add({ login => 'baz', fu => ['foo', 'bar'] });

    db->events->add({
        type => 'e1',
        author => 'foo',
        realm => 'europe',
    });
    db->events->add({
        type => 'e2',
        author => 'bar',
        realm => 'asia',
    });
    db->events->add({
        type => 'e3',
        author => 'baz',
        realm => 'asia',
    });

    _cmp_list
        { for => 'foo' },
        [qw( e2 e1 )];
    _cmp_list
        { for => 'bar' },
        [qw( e2 )];
    _cmp_list
        { for => 'baz' },
        [qw( e3 e2 e1 )];
}

sub list_for_mixed :Tests {
    db->users->add({ login => 'foo', fu => ['bar', 'baz'], fr => ['asia'] });
    db->users->add({ login => 'bar' });
    db->users->add({ login => 'baz' });
    db->users->add({ login => 'yarr' });
    db->users->add({ login => 'arrgh' });

    db->events->add({
        type => 'e1',
        author => 'foo',
        realm => 'europe',
    });
    db->events->add({
        type => 'e2',
        author => 'bar',
        realm => 'europe',
    });
    db->events->add({
        type => 'e3',
        author => 'baz',
        realm => 'europe',
    });
    db->events->add({
        type => 'e4',
        author => 'yarr',
        realm => 'europe',
    });
    db->events->add({
        type => 'e5',
        author => 'arrgh',
        realm => 'asia',
    });

    _cmp_list
        { for => 'foo' },
        [qw( e5 e3 e2 e1 )];
}

sub realm_validation :Tests {
    like exception { db->events->add({ type => 'foo-bar', foo => 'bar', type => 'test' }) }, qr/not defined/;
    like exception { db->events->add({ type => 'foo-bar', foo => 'bar', type => 'test', realm => 'africa' }) }, qr/Unknown realm/;
}

sub load_quests :Tests {
    db->users->add({ login => 'foo', realm => 'europe' });

    my $quest = db->quests->add({
        name => 'q1',
        user => 'foo',
        realm => 'europe',
    });

    my $events = db->events->list({ realm => 'europe' });
    cmp_deeply $events, [
        superhashof({
            type => 'add-quest',
            quest_id => $quest->{_id},
            quest => superhashof({
                name => 'q1'
            })
        })
    ];

    db->quests->update($quest->{_id}, { name => 'q1-revised', user => 'foo' });
    $events = db->events->list({ realm => 'europe' });
    cmp_deeply $events, [
        superhashof({
            quest => superhashof({
                name => 'q1-revised'
            })
        })
    ];
}

__PACKAGE__->new->runtests;
