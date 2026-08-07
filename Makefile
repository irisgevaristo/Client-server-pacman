all:
	$(MAKE) -C server-side
	$(MAKE) -C client-side

clean:
	$(MAKE) -C server-side clean
	$(MAKE) -C client-side clean