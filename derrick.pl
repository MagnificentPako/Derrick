:- use_module(library(http/http_server)).
:- use_module(library(http/http_path)).
:- use_module(library(http/http_session)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_parameters)).
:- use_module('oauth.pl').
:- use_module('oauth_options.pl').

:- debug.

% Only for debugging
:- use_module(library(http/http_error)).

:- multifile http:location/3.
:- dynamic   http:location/3.

http:location(static, '/static', []).

:- initialization
    http_server([port(8080)]).

:- http_handler(root(.),                index_handler, []).
:- http_handler(static('index.js'),     http_reply_file('static/index.js',  []), []).
:- http_handler(static('tau.js'),       http_reply_file('static/tau.js',    []), []).
:- http_handler(static('app.pl'),       http_reply_file('static/app.pl',    []), []).
:- http_handler(static('anoints.pl'),   http_reply_file('static/anoints.pl',[]), []).
:- http_handler(static('style.css'),    http_reply_file('static/style.css', []), []).

:- http_handler(root('stashes'),         stashes_handler, []).
:- http_handler(root(stashes/StashID),   stash_handler(StashID), []).
:- http_handler(root('redirect'),        redirect_handler, []).

logged_in :- http_in_session(SID), http_current_session(SID, logged_in).
token(Token) :- http_in_session(SID), http_current_session(SID, token(Token)).

index_handler(Request) :-
    \+ logged_in, !,
    oauth_options(OauthOptions),
    make_redirect_uri(OauthOptions, Uri),
    http_redirect(moved_temporary, Uri, Request).

index_handler(Request) :-
    logged_in, !,
    http_reply_file('index.html', [], Request).

stashes_handler(_Request) :-
    \+ logged_in, !,
    throw(http_reply(forbidden('/stashes'))).

stashes_handler(_Request) :-
    logged_in, !,
    token(Token),
    oauth_options(OOptions),
    oauth_get(OOptions, Token, '/stash/Sentinel', Res),
    reply_json(Res).

stash_handler(StashID, _Request) :-
    logged_in, !,
    token(Token),
    oauth_options(OOptions),
    format(string(ReqPath), '/stash/Sentinel/~w', [StashID]),
    oauth_get(OOptions, Token, ReqPath, Res),
    reply_json(Res).

redirect_handler(Request) :-
    http_parameters(Request, [
        code(Code, []),
        state(State, [])
    ]),
    oauth_options(OOptions),
    fetch_token(OOptions, Code, State, Token),
    http_in_session(SID),
    http_session_assert(logged_in, SID),
    http_session_assert(token(Token), SID),
    http_redirect(moved_temporary, '/', Request).
    