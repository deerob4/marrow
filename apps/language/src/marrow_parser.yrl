Nonterminals
elem
elems
list
game
trigger
trigger_set
event
event_set
arg_list
tile
paths
path_expr
.

Terminals
'(' ')'
operator events
defgame variables global player 'if' triggers board path
string integer identifier builtin
.

Rootsymbol game.

game -> '(' defgame string elems ')' : {defgame, val('$3'), '$4'}.

% Lists

list -> '(' ')' : [].
list -> '(' elems ')' : '$2'.

% list -> '(' identifier elems ')' : {'$2', '$3'}.
list -> '(' identifier elems ')' : identify_variables('$2', '$3').
list -> '(' builtin elems ')' : {val('$2'), '$3'}.
list -> '(' operator elems ')' : {val('$2'), '$3'}.
list -> '(' builtin ')' : {val('$2'), []}.
list -> '(' identifier ')' : identify_variables('$2', []).

list -> '(' global identifier elem ')' : var_tuple(global, val('$3'), '$4').
list -> '(' player identifier elem ')' : var_tuple(player, val('$3'), '$4').

list -> '(' 'if' elem elem elem ')' : {'if', {'$3', '$4', '$5'}}.

list -> '(' events event_set ')' : {events, '$3'}.
event -> '(' identifier '(' arg_list ')' elems ')' : {val('$2'), '$4', '$6'}.
event_set -> event : ['$1'].
event_set -> event event_set : ['$1' | '$2'].

arg_list -> identifier : [val('$1')].
arg_list -> identifier arg_list : [val('$1') | '$2'].

list -> '(' triggers trigger_set ')' : {triggers, '$3'}.
trigger -> '(' elem elems ')' : {'$2', '$3'}.
trigger_set -> trigger : ['$1'].
trigger_set -> trigger trigger_set : ['$1' | '$2'].

list -> '(' board tile paths ')' : {board, '$3', '$4'}.
path_expr -> '(' path tile tile ')' : {path, '$3', '$4'}.
paths -> path_expr : ['$1'].
paths -> path_expr paths : ['$1' | '$2'].
tile -> '(' integer integer ')' : {val('$2'), val('$3')}.

% Elements

elem -> variables : variables.
elem -> integer : val('$1').
elem -> string : val('$1').
elem -> identifier : val('$1').
elem -> builtin : val('$1').
elem -> operator : val('$1').
elem -> tile : '$1'.
elem -> list : '$1'.

elems -> elem : ['$1'].
elems -> elem elems : ['$1' | '$2'].

Erlang code.

val({_Token, _Line, Value}) -> Value.

var_tuple(Type, Key, Value) -> {Type, Key, Value}.

identify_variables(Identifier, Args) ->
  case {Identifier, Args} of
    {{identifier, _Line, Name}, [Role]} when 
       erlang:is_bitstring(Role);
       Role =/= 'var',
       Role == '?current_player';
       Role == '?current_tile';
       Role == '?current_turn';
       Role == '?player_count';
       Role == '?board_width';
       Role == '?board_height' ->
      {variable, {Role, Name}};

    {{identifier, _Line, Name}, Args} when erlang:is_bitstring(Name) ->
      {event, Name, Args};

    _ ->
      {val(Identifier), Args}
  end.
