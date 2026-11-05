-module(ezic_db).
-include("include/ezic.hrl").
-export([flatzone/2]).

flatzone(Date, ZoneName) ->
  try ezic_zone_map:find(ZoneName) of
    ModuleName ->
      FlatZones = ModuleName:flatzones(),
      {D, #tztime{time = T, flag = F}} = Date,
      DComp = {D, T},
      case lists:filter(filter(DComp, F), FlatZones) of
        [] -> {error, no_zone};
        [FlatZone] -> FlatZone;
        Matches = [_, _] -> {error, {ambiguous_zone, Matches}};
        Matches -> {error, {should_not_happen, {Matches, Date, ZoneName}}}
      end
  catch
    throw:{zone_not_found, _} -> {error, no_zone}
  end.

filter(DComp, u) ->
  fun(#flatzone{utc_from = From, utc_to = To}) ->
    (From =< DComp) and ((DComp =< To) or (To == current))
  end;
filter(DComp, w) ->
  fun(#flatzone{wall_from = From, wall_to = To}) ->
    (From =< DComp) and ((DComp =< To) or (To == current))
  end.
