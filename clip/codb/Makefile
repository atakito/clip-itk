include ../Makefile.inc
CLIP	= ../clip
CLIPFLAGS = -l -a -w -O -n -I . -I .. -I ../include
CLIPFLAGS2 =
CFLAGS = -I.. -I../include -I$(CLIPROOT)
CLIPLIBS  =
OBJS  = codb_list.o codb.o codb_funcs.o codb_oql.o codb_install.o \
	codb_err.o codb_cache.o codb_cobra.o codb_uni.o list_id.o\
	codb_dep.o codb_dict.o \
	dict_dbf.o dep_dbf.o ext_dbf.o count_dbf.o \
	dict_all.o dep_all.o \
	codb_sql.o dict_sql.o \
	dict_cobra.o dep_cobra.o

.SUFFIXES: .prg .o .po

LIB = libclip-codb.a
SLIB = libclip-codb$(DLLSUFF)

LIB_QUERY = libcodb-query.a
SLIB_QUERY = libcodb-query$(DLLSUFF)
OBJS_QUERY = codb_query.o formatter.o

export CFLAGS

all:    $(OBJS) $(OBJS_QUERY) $(LIB) $(SLIB) $(LIB_QUERY) $(SLIB_QUERY)
#	../clip_makelib libclip-codb.a $(OBJS)
#	../clip_makeslib libclip-codb $(OBJS)
#	rm -rf *.c

clean:
	rm -rf *.exe *.o *.c *.s *.a *.so *.po *.ppo *.pa *.log *.uri *.b *.BAK *.bak *~ core* *core codb_mk clip_ab test
	rm -rf *.ex *.nm

install: all
	../clip_cp libclip-codb $(DESTDIR)$(CLIPROOT)/lib
	../clip_cp libcodb-query $(DESTDIR)$(CLIPROOT)/lib
	tar cf - codb.ch codbcfg.ch codb_dbf.ch | (cd $(DESTDIR)$(CLIPROOT)/include && tar xf -)

$(LIB): $(OBJS)
	rm -f $(LIB)
	../clip_makelib $(LIB) $(OBJS)

$(SLIB): $(LIB)
	../clip_makeslib $(SLIB) $(LIB)

$(LIB_QUERY): $(OBJS_QUERY)
	rm -f $(LIB_QUERY)
	../clip_makelib $(LIB_QUERY) $(OBJS_QUERY)

$(SLIB_QUERY): $(LIB_QUERY)
	../clip_makeslib $(SLIB_QUERY) $(OBJS_QUERY)

.prg.o:
	$(CLIP) $(CLIPFLAGS) $(CLIPFLAGS2) $<

.prg.po:
	$(CLIP) $(CLIPFLAGS) -p $<

