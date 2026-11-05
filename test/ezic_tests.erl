-module(ezic_tests).
-include("include/ezic.hrl").
-include_lib("eunit/include/eunit.hrl").

smoke_test_() ->
    [
     %% utc_to_local - normal tests
     ?_assertEqual({{2012,12,17},{13,20,0}}, ezic:utc_to_local({{2012,12,17},{4,20,0}}, "Asia/Tokyo"))
     , ?_assertEqual({{2012,12,16},{23,20,0}}, ezic:utc_to_local({{2012,12,17},{4,20,0}}, "America/Jamaica"))
     , ?_assertEqual({{2012,12,16},{20,20,0}}, ezic:utc_to_local({{2012,12,17},{4,20,0}}, "America/Los_Angeles"))

     %% local_to_utc - normal tests
     , ?_assertEqual({{2012,12,17},{4,20,0}}, ezic:local_to_utc({{2012,12,17},{13,20,0}}, "Asia/Tokyo"))
     , ?_assertEqual({{2012,12,17},{4,20,0}}, ezic:local_to_utc({{2012,12,16},{23,20,0}}, "America/Jamaica"))
     , ?_assertEqual({{2012,12,17},{4,20,0}}, ezic:local_to_utc({{2012,12,16},{20,20,0}}, "America/Los_Angeles"))
    ].


local_to_utc_errors_test_() ->
    [
     ?_assertMatch({error, {ambiguous_zone, _}}, ezic:local_to_utc({{2010,11,7},{1,0,0}}, "America/Los_Angeles"))
     , ?_assertEqual({error, no_zone}, ezic:local_to_utc({{2010,3,14},{2,30,0}}, "America/Los_Angeles"))
    ].


%% Tests overlap logic around timezones that have odd DST rules
local_to_utc_funkyDST_test_() ->
    [
     %% gap (1948-05-02 00:00 -> 01:00 JST/JDT)
     ?_assertMatch({{1948,5,1},{14,0,0}}, ezic:local_to_utc({{1948,5,1},{23,00,00}}, "Asia/Tokyo"))
     , ?_assertMatch({error, no_zone}, ezic:local_to_utc({{1948,5,2},{0,00,00}}, "Asia/Tokyo"))
     , ?_assertMatch({{1948,5,1},{15,0,0}}, ezic:local_to_utc({{1948,5,2},{1,00,00}}, "Asia/Tokyo"))

     %% overlap (1948-09-12 00:00..00:59:59 JDT/JST)
     , ?_assertMatch({{1948,9,11},{13,30,0}}, ezic:local_to_utc({{1948,9,11},{23,30,00}}, "Asia/Tokyo"))
     , ?_assertMatch({error, {ambiguous_zone, _}}, ezic:local_to_utc({{1948,9,12},{0,00,00}}, "Asia/Tokyo"))
     , ?_assertMatch({{1948,9,11},{16,0,0}}, ezic:local_to_utc({{1948,9,12},{1,00,00}}, "Asia/Tokyo"))

     %% DST end (1951-05-06 00:00 gap & 1951-09-09 00:00 overlap)
     , ?_assertMatch({error, no_zone}, ezic:local_to_utc({{1951,5,6},{0,0,0}}, "Asia/Tokyo")) %% final DST gap
     , ?_assertMatch({{1951,5,5},{15,0,0}}, ezic:local_to_utc({{1951,5,6},{1,0,0}}, "Asia/Tokyo")) %% DST in effect for the last time
     , ?_assertMatch({error, {ambiguous_zone, _}}, ezic:local_to_utc({{1951,9,9},{0,0,0}}, "Asia/Tokyo")) %% DST overlap
     , ?_assertMatch({{1951,9,8},{16,0,0}}, ezic:local_to_utc({{1951,9,9},{1,0,0}}, "Asia/Tokyo")) %% DST off for the last time
     , ?_assertMatch({{1952,5,3},{17,0,0}}, ezic:local_to_utc({{1952,5,4},{2,0,0}}, "Asia/Tokyo")) %% ensure DST not in effect for 1952
    ].

has_dst_local_test_() ->
    [
     ?_assertMatch(false, ezic:has_dst_local({{1998,3,1},{1,30,0}}, "Europe/Paris")),
     ?_assertMatch(true, ezic:has_dst_local({{1998,9,30},{1,30,0}}, "Europe/Paris")),
     ?_assertMatch(true, ezic:has_dst_local({{1998,8,30},{3,30,0}}, "America/Denver")),
     ?_assertMatch(false, ezic:has_dst_local({{1998,10,30},{3,30,0}}, "America/Denver")),
     %% weird date
     ?_assertMatch(false, ezic:has_dst_local({{1998,2,31},{10,30,0}}, "Europe/Paris")),
     %% invalid zone
     ?_assertException(error, {case_clause, {error, no_zone}}, ezic:has_dst_local({{1998,10,20},{12,30,0}}, "non_existent")),
     %% ambiguous zone
     ?_assertException(error, {case_clause, {error, {ambiguous_zone, _}}}, ezic:has_dst_local({{1998,10,25},{1,30,0}}, "America/Denver"))
    ].

has_dst_utc_test_() ->
    [
     ?_assertMatch(false, ezic:has_dst_utc({{1998,3,28},{13,30,0}}, "Europe/Paris")),
     ?_assertMatch(true, ezic:has_dst_utc({{1998,3,29},{1,30,0}}, "Europe/Paris")),
     ?_assertMatch(true, ezic:has_dst_utc({{1998,10,25},{7,59,59}}, "America/Denver")),
     ?_assertMatch(false, ezic:has_dst_utc({{1998,10,25},{8,0,0}}, "America/Denver")),
     %% weird date
     ?_assertMatch(false, ezic:has_dst_utc({{1998,2,31},{13,30,0}}, "Europe/Paris")),
     %% invalid zone
     ?_assertException(error, {case_clause, {error, no_zone}}, ezic:has_dst_utc({{1998,10,25},{1,30,0}}, "non_existent"))
    ].

