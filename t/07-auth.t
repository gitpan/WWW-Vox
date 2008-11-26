use Test::More qw( no_plan );

use Test::MockObject;


sub make_mock_ua {
    my $mock_ua = Test::MockObject->new;
    Test::MockObject->fake_module(
        'LWP::UserAgent',
        new => sub { $mock_ua },
    );

    require HTTP::Response;
    my $res = HTTP::Response->new;
    $res->code(200);
    $res->header('Content-Type', 'text/javascript+json');
    $res->content(q/ { "error": null } /);
    
    $mock_ua->mock( request => sub { $res } );
}

my $mock_ua = make_mock_ua();


use_ok('WWW::Vox');

{
    my $vox = WWW::Vox->new;
    ok($vox, 'instantiated a vox client');

    my $result = eval { $vox->request('Explore.Search', { tag => 'vox hunt', type => 'Post' }) };
    ok(!$@, 'successfully searched for vox hunt posts');
    diag(Data::Dumper::Dumper($@)) if $@;
}

{
    my $mock_cookie_jar;
    $mock_ua->mock( cookie_jar => sub { shift; ($mock_cookie_jar) = @_ } );

    use_ok('WWW::Vox::Auth::Cookies');
    my $auth = WWW::Vox::Auth::Cookies->new(
        cookies => 'my mock cookie jar value',
    );

    my $vox = WWW::Vox->new( auth => $auth );
    ok($vox, 'instantiated a cookie auth vox client');

    my $result = eval { $vox->request('Tag.Autocomplete', { tag => 'vox h' }) };
    ok(!$@, 'successfully autocompleted a vox hunt tag');
    diag(Data::Dumper::Dumper($@)) if $@;

    is($mock_cookie_jar, 'my mock cookie jar value', q{cookie auth set the UA's cookie jar value});
}

