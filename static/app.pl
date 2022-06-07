:- use_module(library(js)).
:- use_module(library(lists)).
:- use_module(library(dom)).
:- use_module(library(format)).
:- use_module(library(fix_this_shit)).

fmts(String, Fs, Arguments) :-
    phrase(format_(Fs, Arguments), String).

generate_ui :-
    create(select, Select),
    set_attr(Select, id, 'stash_id'),

    create(ul, StashContainer),
    set_attr(StashContainer, id, 'stash_container'),

    get_by_id(container, Container),
    append_child(Container, Select),
    append_child(Container, StashContainer).

reset_stash_container :-
    get_by_id(stash_container, StashContainer),
    forall(parent_of(Child, StashContainer), remove(Child)).

item_name(Item, Name) :-
    member((name-ItemName), Item),
    member((baseType-Type), Item),
    atom_codes(ItemName, INL),
    (( length(INL, L)
    , L > 0)
    -> Name = ItemName;
       Name = Type).

add_item_to_container(Item) :-
    get_by_id(stash_container, Container),
    member((icon-Icon), Item),
    create(li, ItemElement),
    create(img, ItemImg),
    set_attr(ItemImg, src, Icon),
    create(p, ItemTxt),
    item_name(Item, ItemName),
    %member((x-X), Item),
    %member((y-Y), Item),
    %fmts(ItemText, '~w at position ~wx, ~wy.', [ItemName, X, Y]),
    fmts(Test, '~w', [ItemName]),
    write(Item),
    write(Test),
    html(ItemTxt, ItemName),
    append_child(ItemElement, ItemImg),
    append_child(ItemElement, ItemTxt),
    append_child(Container, ItemElement).

add_option(Select, Tab) :-
    member((name-Name), Tab),
    member((id-ID), Tab),
    create(option, Option),
    set_attr(Option, 'value', ID),
    html(Option, Name),
    append_child(Select, Option).

is_anointed_jewelry(Item) :-
    member((baseType-Type), Item),
    %member((enchantMods-_), Item),
    (atom_concat(_, 'Amulet', Type); 
     atom_concat(_, 'Ring', Type)).

is_useful_anoint(Item) :-
    true.
    %member((enchantMods-Enchants), Item),
    %member(Enchantment, Enchants),
    %anoint(Oils, Enchantment),
    %member(Oil, Oils),
    %oil_gte(Oil, opalscent).

on_select(Event) :-
    event_property(Event, target, Target),
    fixed_for_you(Target, value, Value),
    atomic_list_concat(['/stashes/', Value], URL),
    ajax(get, URL, Res, [type(json)]),
    json_prolog(Res, DataRaw),
    member((stash-Stash), DataRaw),
    member((items-Items), Stash),
    include(is_anointed_jewelry, Items, FilteredJewelry),
    include(is_useful_anoint, FilteredJewelry, FilteredAnoints),
    reset_stash_container,
    forall(member(X, FilteredAnoints), add_item_to_container(X)).

init :- 
    generate_ui,
    ajax(get, '/stashes', Res, [type(json)]),
    json_prolog(Res, DataRaw),
    member((stashes-Data), DataRaw),
    get_by_id(stash_id, Select),
    forall(member(X, Data), add_option(Select, X)),
    bind(Select, change, Event, (on_select(Event))).