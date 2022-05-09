:- module(oauth, [make_redirect_uri/2, fetch_token/4, oauth_get/4]).

:- use_module(library(http/http_server)).
:- use_module(library(http/http_client)).
:- use_module(library(http/http_ssl_plugin)).
:- use_module(library(http/http_json)).
:- use_module(library(url)).
:- use_module(library(random)).
:- use_module(library(option)).

:- debug.

:- dynamic valid_state/1.

valid_state("") :- false.

generate_state(State) :-
    generate_state_n(State, 16).

generate_state_n('', 0).
generate_state_n(State, N) :-
    random_between(65, 90, I),
    char_code(S, I),
    N1 is N-1,
    generate_state_n(State2, N1),
    string_concat(State2, S, State).

make_redirect_uri(Options, Uri) :-
    option(host(Host), Options),
    option(auth_path(Path), Options),
    option(client_id(ClientId), Options),
    option(redirect_uri(RedirectUri), Options),
    option(scope(Scope), Options),

    generate_state(State),
    assertz(valid_state(State)),
    parse_url(Uri, [
        protocol(https),
        host(Host),
        path(Path),
        search([ response_type = 'code'
               , client_id =  ClientId
               , redirect_uri = RedirectUri
               , scope = Scope
               , state = State
               ])
    ]).

fetch_token(Options, Code, State, Token) :- 
    %valid_state(State),
    option(host(Host), Options),
    option(token_path(Path), Options),
    option(client_id(ClientId), Options),
    option(client_secret(ClientSecret), Options),
    option(redirect_uri(RedirectUri), Options),
    option(scope(Scope), Options),
    option(user_agent(UA), Options),

    PostData = [ grant_type('authorization_code')
               , client_id(ClientId)
               , client_secret(ClientSecret)
               , redirect_uri(RedirectUri)
               , code(Code)
               , scope(Scope)
               ],
    http_post( [protocol(https), host(Host), path(Path)]
             , form(PostData)
             , Token
             , [user_agent(UA), json_object(dict)]
             ).

oauth_get(Options, Token, Path, Res) :-
    option(api_host(Host), Options),
    option(user_agent(UA), Options),
    format(string(Auth), 'Bearer ~w', [Token.access_token]),
    http_get([protocol(https), host(Host), path(Path)], Res, [json_object(dict), user_agent(UA), request_header(authorization=Auth)]).