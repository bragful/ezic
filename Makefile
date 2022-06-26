ifdef REBAR_BARE_COMPILER_OUTPUT_DIR
	EBIN = ${REBAR_BARE_COMPILER_OUTPUT_DIR}/ebin
else ifdef REBAR_BUILD_DIR
	EBIN = ${REBAR_BUILD_DIR}/lib/ezic/ebin
else		
	EBIN = "ebin"
endif

zones:
	wget "https://data.iana.org/time-zones/tzdata-latest.tar.gz"
	mkdir -p priv/tzdata
	tar -xvzf tzdata-latest.tar.gz -C priv/tzdata
	rm tzdata-latest.tar.gz
	erl -pa ${EBIN} -s ezic_generator generate -s erlang halt -noinput -noshell
	erlc -o ${EBIN} zones/*.erl
