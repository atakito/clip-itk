#include "r2d2lib.ch"

function r2d2_report1_xml(_queryArr)

local err, _query
local oDict,oDep, oDep02,oDict02
local accPost, acc_chart, osb_class
local beg_date:=date(),end_date:=date(), account:=""
local connect_id:="", connect_data
local i,j,k,s1,s2,tmp,obj
local acc_list, acc_objs,acc_s
local post_list, d_data,k_data, d_list,k_list, d_res,k_res
local d_cache:=map(), k_cache:=map()
local c_data
local cache:=map()

	errorblock({|err|error2html(err)})

	_query:=d2ArrToMap(_queryArr)
	outlog(__FILE__,__LINE__, _query)

	if "CONNECT_ID" $ _query
		connect_id := _query:connect_id
	endif

	if "BEG_DATE" $ _query
		beg_date := ctod(_query:beg_date,"dd.mm.yyyy")
	endif
	if "END_DATE" $ _query
		end_date := ctod(_query:end_date,"dd.mm.yyyy")
	endif
	if "ACCOUNT" $ _query
		account := upper(_query:account)
	endif

	if !empty(connect_id)
		connect_data := cgi_connect_data(connect_id)
	endif
	if !empty(connect_data)
		beg_date := connect_data:beg_date
		end_date := connect_data:end_date
	endif

	if empty(account) .or. empty(beg_date) .or. empty(end_date)
		//cgi_html_header()
		cgi_xml_header()

		? '<body>'
		? "Error: bad parameters ! "
		if empty(beg_date) .or. empty(end_date)
			?? "PERIOD not defined "
		endif
		if empty(account)
			?? "ACCOUNT not defined "
		endif
		? "Usage:"
		? "    report1?beg_date=<date>& end_date=<date>& account=<account_code>"
		?
		return
	endif

//	cgi_html_header("������� �� �����")
	cgi_xml_header()
	? '<body>'

	oDep := codb_needDepository("ACC0101")
	if empty(oDep)
		cgi_xml_error( "Depository not found: ACC0101" )
		return
	endif
	oDict := oDep:dictionary()

	accPost:= oDict:classBodyByName("accpost")
	if empty(accPost)
		cgi_html_error( "Class description not found: accpost" )
		return
	endif

	oDep02 := codb_needDepository("GBL0201")
	if empty(oDep)
		cgi_xml_error( "Depository not found: GBL0201" )
		return
	endif
	oDict02 := oDep02:dictionary()

	acc_chart:= oDict02:classBodyByName("acc_chart")
	if empty(acc_chart)
		cgi_html_error( "Class description not found: acc_chart" )
		return
	endif

	/* search account in acc_chart*/
	acc_list:={}; acc_objs:={}; tmp:=""
	obj:= oDep02:getValue(account)
	if !empty(obj)
		aadd(acc_objs,obj)
		aadd(acc_list,account)
		cache[obj:id] := obj
	else
		set exact off
		tmp := oDep02:select(acc_chart:id,,,'code="'+account+'"')
		set exact on
	endif
	if !empty(tmp)
		for i=1 to len(tmp)
			obj:=oDep02:getValue(tmp[i])
			if empty(obj)
				loop
			endif
			aadd(acc_objs,obj)
			aadd(acc_list,tmp[i])
			cache[obj:id] := obj
		next
	endif

	if empty(acc_list)
		cgi_html_error( "ACCOUNT not found: "+account )
		return
	endif

	post_list := {}
	s1 := 'odate>=stod("'+dtos(beg_date)+'") .and. odate<=stod("'+dtos(end_date)+'")'
	for i=1 to len(acc_list)
		s2 := ' .and. (daccount="'+acc_list[i]+'" .or. kaccount="'+acc_list[i]+'")'
		tmp:=oDep:select(accpost:id,,,s1+s2)
		//? s1,s2
		//? tmp
		for j=1 to len(tmp)
			aadd(post_list,tmp[j])
		next
	next
	outlog(__FILE__,__LINE__,len(post_list),post_list)
//	return

	d_data := {}; k_data := {}
	d_list := {}; k_list := {}

	for i=1 to len(post_list)
		obj:=oDep:getValue(post_list[i])
		if empty(obj)
			loop
		endif
		j:=ascan(acc_list,obj:daccount)
		if j>0
			tmp:=obj:daccount+obj:kaccount
			//? tmp,d_cache,"<BR/>"
			if  tmp $ d_cache
				j := d_cache[tmp]
				j:summa += obj:summa
			else
				aadd(d_data,obj)
				d_cache[tmp] := atail(d_data)
			endif
		endif
		j:=ascan(acc_list,obj:kaccount)
		if j>0
			tmp:=obj:daccount+obj:kaccount
			if  tmp $ k_cache
				j := k_cache[tmp]
				j:summa += obj:summa
			else
				aadd(k_data,obj)
				k_cache[tmp] := atail(k_data)
			endif
		endif
	next
	for i=1 to len(d_data)
		k :=map()
		obj:=d_data[i]
		tmp := NIL
		if obj:daccount $ cache
			tmp:= cache[obj:daccount]
		else
			tmp := oDep02:getValue(obj:daccount)
			if !empty(tmp)
				cache[tmp:id] := tmp
			endif
		endif
		if empty(tmp)
			cgi_html_error("ACCOUNT reference not found:"+obj:daccount)
			loop
		endif
		k:debet := tmp:code
		tmp := NIL
		if obj:kaccount $ cache
			tmp:= cache[obj:kaccount]
		else
			tmp := oDep02:getValue(obj:kaccount)
			if !empty(tmp)
				cache[tmp:id] := tmp
			endif
		endif
		if empty(tmp)
			cgi_html_error("ACCOUNT reference not found:"+obj:kaccount)
			loop
		endif
		k:kredit := tmp:code
		k:summa  := obj:summa
		aadd(d_list,k)
	next
	for i=1 to len(k_data)
		obj:=k_data[i]
		k:=map()
		tmp := NIL
		if obj:daccount $ cache
			tmp:= cache[obj:daccount]
		else
			tmp := oDep02:getValue(obj:daccount)
			if !empty(tmp)
				cache[tmp:id] := tmp
			endif
		endif
		if empty(tmp)
			cgi_html_error("ACCOUNT reference not found:"+obj:daccount)
			loop
		endif
		k:debet := tmp:code
		tmp := NIL
		if obj:kaccount $ cache
			tmp:= cache[obj:kaccount]
		else
			tmp := oDep02:getValue(obj:kaccount)
			if !empty(tmp)
				cache[tmp:id] := tmp
			endif
		endif
		if empty(tmp)
			cgi_html_error("ACCOUNT reference not found:"+obj:kaccount)
			loop
		endif
		k:kredit := tmp:code
		k:summa  := obj:summa
		aadd(k_list,k)
	next
	asort(d_list,,,{|x,y|x:kredit<y:kredit})
	d_res := resumm(d_list)
	//?
	//? d_list
	//? d_res
	asort(k_list,,,{|x,y|x:debet<y:debet})
	k_res := resumm(k_list)
	//? k_list
	//? k_res

	**************
    acc_s := ""
    j:=len(acc_objs)
    for i=1 to j
    	acc_s+=acc_objs[i]:code
    	if i!=j
        	acc_s+=","
        endif
    next
	? '<div>������� �� �������� �������� �� �����(��): '+acc_s //account
	? '�� ������ � '+dtoc(beg_date)+' �� '+dtoc(end_date)+'</div>'
	? '<table cellpadding="2" cellspacing="0" border="1" width="80%" align="center">'
	? '<tr>'
	? '	<th valign="top" width="10%"><br/></th>'
	? '	<th valign="top" width="10%"><br/></th>'
	? '	<th valign="top" width="30%">������ �� ������</th>'

	? '	<th valign="top" width="10%"><br/></th>'
	? '	<th valign="top" width="10%"><br/></th>'
	? '	<th valign="top" width="30%">������ �� �������</th>'
	? '</tr>'
	? '<tbody>'

	j:=max(len(d_res),len(k_res))

	for i=1 to j
		if i<=len(d_res)
			tmp := d_res[i]
		else
			tmp := empty_data()
		endif
		? '<tr>'
		? '	<td valign="top" align="left">'+tmp:debet+'</td>'
		? '	<td valign="top" align="left">'+tmp:kredit+'</td>'
		? '	<td valign="top">'+Str(tmp:summa,14,2)+'</td>'
		if i<=len(k_res)
			tmp := k_res[i]
		else
			tmp := empty_data()
		endif
		? '	<td valign="top" align="left">'+tmp:debet+'</td>'
		? '	<td valign="top" align="left">'+tmp:kredit+'</td>'
		? '	<td valign="top">'+Str(tmp:summa,14,2)+'</td>'
		? '</tr>'
	next
	? '</tbody>'
	? '</table>'
	? '<BR/>'
	**********************
	? '<div>������� �� ��������:</div>'
	? '<table cellpadding="2" cellspacing="2" border="1" width="80%" align="center">'
	? '<tr>'
	? '	<th valign="top" width="10%">����</th>'
	? '	<th valign="top">������ �����</th>'
	? '	<th valign="top">������ ������</th>'
	? '	<th valign="top">������ �����</th>'
	? '	<th valign="top">������ ������</th>'
	? '	<th valign="top">����� �����</th>'
	? '	<th valign="top">����� ������</th>'
	? '</tr>'
	? '<tbody>'

	osb_class := oDict:classBodyByName("os_balance")
	if empty(osb_class)
		cgi_html_error("Class description not found: os_balance")
		return
	endif
	s1:= ' .and. odate>=stod("'+dtos(beg_date)+ '") .and. odate<=stod("'+dtos(end_date)+ '")'
	s2:= ' .and. odate<stod("'+dtos(beg_date)+ '")'
	for i=1 to len(acc_objs)
		tmp := acc_objs[i]
		c_data:=r2d2_get_osb_data(oDep,osb_class:id,tmp,beg_date,end_date,s1,s2)
//		? "c_data",c_data
		? '<tr>'
		? '<td valign="top" align="left" >'+tmp:code+'</td>'
		? '<td valign="top" align="right" >'+str(c_data:bd_summa,14,2)+'</td>'
		? '<td valign="top" align="right" >'+str(c_data:bk_summa,14,2)+'</td>'
		? '<td valign="top" align="right" >'+str(c_data:od_summa,14,2)+'</td>'
		? '<td valign="top" align="right" >'+str(c_data:ok_summa,14,2)+'</td>'
		? '<td valign="top" align="right" >'+str(c_data:ed_summa,14,2)+'</td>'
		? '<td valign="top" align="right" >'+str(c_data:ek_summa,14,2)+'</td>'
		? '</tr>'
	next
	? '</tbody>'
	? '</table>'
	? '<div id="end"></div></body>'

	//cgi_html_footer()
	?
	return

***********************
static function empty_data()
	static ret
	if empty(ret)
		ret := map()
		ret:debet := "<BR/>"
		ret:kredit := "<BR/>"
		ret:summa  := 0.00
	endif
return ret
***********************
static function resumm(a_list)
	local res:={},i,cel,scel
	res:=a_list
return res