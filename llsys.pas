(*  Login check Level System "LLSYS.PAS" 獅堂　光  ver1.01  

	このソースファイルは TAB8 を使用しています

	Ver1.00 暇なので作る。計算の作動が妖しいので苦戦した ;(
	Ver1.01 ところどころ修正 :)

*)

unit llsys;

{----------------------------------------------------------------------------}
interface

uses bbsheadr,io,mailsys,filmangr,{$IFDEF IBMPC}mchedeibm{$ELSE}mchde98b{$ENDIF};

procedure Login_Count;
procedure EditLogData;
procedure New_User(i:integer);

{----------------------------------------------------------------------------}
implementation

type
	llsystem  = record
		flag	: boolean;
		logyear : integer;
		logmonth: integer;
		logday  : integer;
		slogyear : integer;
		slogmonth: integer;
		slogday  : integer;
	end;

const	llfname	  = 'llsys.dat';
	llsysver  = 'Login Check Level System Ver1.01 (c) 1996 獅堂 光☆ﾐ';

	DownMess1 = '規定された期間ﾛｸﾞｲﾝが無いのでLvをダウンしました。';

	CheckMonth= 3;			(* 単位:月			*)
					(* 12ヶ月まで作動保証 (^^;)	*)
					(* でも計算自信なし (^^;)	*)
					(* 0 だと作動しない		*)

var
	llfile	: file of llsystem;
	lldata	: llsystem;
 	lllock	: boolean;

{----------------------------------------------------------------------------}


procedure ReadUserData;	(* ﾃﾞｰﾀの読みとり *)

begin
	if not cts then exit;
	if (_^.usernum=0)and(_^.access<=1) then exit;
	while lllock do TransferNext;
	lllock := true;
	{$I-}
	assign(llfile,llfname);
	reset(llfile);
	seek(llfile,_^.usernum-1);
	read(llfile,lldata);
	close(llfile);
	{$I+}
	lllock := false;
	TransferNext;
end;


procedure New_User(i:integer);	(* 新しい会員処理 *)

begin
	if not cts then exit;
	if (_^.usernum=0)and(_^.access<=1) then exit;
	while lllock do TransferNext;
	lllock := true;
	{$I-}
	assign(llfile,llfname);
	reset(llfile);
	{$I+}
	with lldata do begin
		flag	:=false; logyear  :=0;
		logmonth:=0;	 logday   :=0;
		slogyear:=0;	 slogmonth:=0;
		slogday :=0;
	end;
	{$I-}
	seek(llfile,i);
	write(llfile,lldata);
	close(llfile);
	{$I+}
	lllock := false;
	TransferNext;
end;


procedure ChengeLevel;	(* ﾚﾍﾞﾙの変更 *)

var	i	: integer;
	idprof	: sysid;

begin
	if not cts then exit;
	if (_^.usernum=0)and(_^.access<=1) then exit;
	while islockB(idfil,_^.usernum-1) do TransferNext;
	{$I-}
	lockB(idfil,_^.usernum-1);
	seekB(idfil,_^.usernum-1);
	readB(idfil,@idprof);
	idprof.acc:=1;
	seekB(idfil,_^.usernum-1);
	writeB(idfil,@idprof);
	unlockB(idfil);
	{$I+}
	for i:=0 to MaxCnNum do begin
		if (cvl[i]^.usernum=_^.usernum) then begin
			cvl[i]^.access      := idprof.acc;
		end;
	end;
	lineout('');
	lineout(bell+DownMess1);
	lineout('');
end;


procedure CheckUser;	(* ﾛｸﾞｲﾝ日時のﾁｪｯｸ  計算嫌い ;( *)

var	Checkflag1	: boolean;
	Checkflag2	: boolean;
	temp		: integer;

begin
	if not cts then exit;
	if (_^.usernum=0)and(_^.access<=1) then exit;
	ReadUserData;
	Checkflag1 := false;
	Checkflag2 := false;
	if (lldata.slogyear<>lldata.logyear)and 
	(lldata.slogmonth=lldata.logmonth)and(CheckMonth<=12) then begin
		if (lldata.slogday<=lldata.logday) then
			Checkflag1 := true
		else	Checkflag1 := false;
	end;
	if (lldata.slogyear=lldata.logyear)and(Checkflag1=false) then begin
		if (lldata.logmonth-lldata.slogmonth)>=CheckMonth then begin
			Checkflag1 := true;
			if (lldata.logmonth-lldata.slogmonth)=CheckMonth then
			Checkflag2 := true;
		end;
	end;
	if (lldata.slogyear=(lldata.logyear-1))and(Checkflag1=false) then begin
		temp:=lldata.slogmonth+12;
		if (temp-lldata.logmonth)>=CheckMonth then begin
			Checkflag1 := true;
			if (temp-lldata.logmonth)=CheckMonth then
			Checkflag2 := true;
		end;
	end;
	if (lldata.slogyear=(lldata.logyear-2))and(Checkflag1=false) then begin
		temp:=lldata.slogmonth+24;
		if (temp-lldata.logmonth)>=CheckMonth then begin
			Checkflag1 := true;
			if (temp-lldata.logmonth)=CheckMonth then
			Checkflag2 := true;
		end;
	end;
	if (Checkflag2=true)and(Checkflag1=true) then begin
		if (lldata.slogday<=lldata.logday) then
			Checkflag1 := true
		else	Checkflag1 := false;
	end;
	if CheckMonth = 0 then 	Checkflag1 := false;
	if Checkflag1 = true then ChengeLevel;
end;


procedure Login_Count;	(* ﾛｸﾞｲﾝ日時の更新 *)

begin
	if not cts then exit;
	if (_^.usernum=0)and(_^.access<=1) then exit;
	while lllock do TransferNext;
	lllock := true;
	{$I-}
	assign(llfile,llfname);
	reset(llfile);
	seek(llfile,_^.usernum-1);
	read(llfile,lldata);
	{$I+}
	clock(year, month, day, hour, min, sec);
	if lldata.logday = 0 then begin
		if _^.access = sysop then lldata.flag:=true;
		lldata.logyear  :=year;
		lldata.logmonth :=month;
		lldata.logday   :=day;
	end;
	if _^.usernum=1 then begin
		if lldata.flag = false then lldata.flag := true;
	end;
	lldata.slogyear :=lldata.logyear;
	lldata.slogmonth:=lldata.logmonth;
	lldata.slogday  :=lldata.logday;
	lldata.logyear  :=year;
	lldata.logmonth :=month;
	lldata.logday   :=day;
	{$I-}
	seek(llfile,_^.usernum-1);
	write(llfile,lldata);
	close(llfile);
	{$I+}
	lllock := false;
	TransferNext;
	{ １ヶ月以内ならﾁｪｯｸﾙｰﾁﾝに飛ばない用にする }
	if (lldata.flag=false)and((lldata.slogmonth<>lldata.logmonth)or(lldata.slogyear<>lldata.logyear)) then 
		CheckUser;
end;


procedure EditLogData;

var	idnum	: integer;
	temp	: integer;
	i	: integer;

begin
	if not cts then exit;
	if (_^.usernum=0)and(_^.access<=1) then exit;
	temp:=0;
	_^.prompt := 'ユーザーのＩＤは？ (?:ﾕｰｻﾞｰﾘｽﾄ [RET]:end)>';
	idnum := getid;
	if (idnum<1) then begin
		lineout('');
		lineout('ＩＤ指定エラー');
	end else begin
		while lllock do TransferNext;
		lllock := true;
		{$I-}
		assign(llfile,llfname);
		reset(llfile);
		seek(llfile,idnum-1);
		read(llfile,lldata);
		close(llfile);
		{$I+}
		lllock := false;
		TransferNext;
		repeat
			lineout('');
			lineout(' (1) 前回ﾛｸﾞｲﾝ年 : '+_str(lldata.slogyear,5));
			lineout(' (2) 前回ﾛｸﾞｲﾝ月 : '+_str(lldata.slogmonth,5));
			lineout(' (3) 前回ﾛｸﾞｲﾝ日 : '+_str(lldata.slogday,5));
			lineout(' (4) 今回ﾛｸﾞｲﾝ年 : '+_str(lldata.logyear,5));
			lineout(' (5) 今回ﾛｸﾞｲﾝ月 : '+_str(lldata.logmonth,5));
			lineout(' (6) 今回ﾛｸﾞｲﾝ日 : '+_str(lldata.logday,5));
			stringout(' (7) 規制フラグ  : ');
			if lldata.flag = true then lineout('true')
			else			   lineout('false');
			lineout('');
			_^.prompt:='どれを変更しますか(  1-7  0:END  )>';
			temp:=getint(7,0,false);
			case temp of
				1 : begin
					lineout('');
					_^.prompt:='前回ﾛｸﾞｲﾝ年は？>';
					lldata.slogyear:=getint(9999,0,false);
				end;
				2 : begin
					lineout('');
					_^.prompt:='前回ﾛｸﾞｲﾝ月は？>';
					lldata.slogmonth:=getint(9999,0,false);
				end;
				3 : begin
					lineout('');
					_^.prompt:='前回ﾛｸﾞｲﾝ日は？>';
					lldata.slogday:=getint(9999,0,false);
				end;
				4 : begin
					lineout('');
					_^.prompt:='今回ﾛｸﾞｲﾝ年は？>';
					lldata.logyear:=getint(9999,0,false);
				end;
				5 : begin
					lineout('');
					_^.prompt:='今回ﾛｸﾞｲﾝ月は？>';
					lldata.logmonth:=getint(9999,0,false);
				end;
				6 : begin
					lineout('');
					_^.prompt:='今回ﾛｸﾞｲﾝ日は？>';
					lldata.logday:=getint(9999,0,false);
				end;
				7 : begin
					lineout('');
					_^.prompt:='(0:true 1:false)>';
					i:=getint(1,0,false);
					if i=0 then lldata.flag := true;
					if i=1 then lldata.flag := false;
				end;
			end;
		until (temp=0)or(not cts);
		while lllock do TransferNext;
		lllock := true;
		{$I-}
		assign(llfile,llfname);
		reset(llfile);
		seek(llfile,idnum-1);
		write(llfile,lldata);
		close(llfile);
		{$I+}
		lllock := false;
		TransferNext;
	end;
end;


{----------------------------------------------------------------------------}

var	ids	: file of sysid;
	int	: integer;

begin
	{$I-}assign(llfile,llfname);{$I+}
	{$I-}reset(llfile);{$I+}
	if ioresult <> 0 then begin
		writeln('ＬoginＣheckＬevelＳystem  ＤataＦileを制作しますね(^^)');
		rewrite(llfile);
		assign(ids,mesdir+'ids.bbs');
		{$I-}reset(ids);{$I+}
		if ioresult <> 0 then begin
			writeln(' IDS.BBS がないﾐﾀｲﾅ(^^)');
			with lldata do begin
				flag	:=false; logyear  :=0;
				logmonth:=0;	 logday   :=0;
				slogyear:=0;	 slogmonth:=0;
				slogday :=0;
			end;
			for int:=0 to 3 do begin
				{$I-}
				seek(llfile,int);
				write(llfile,lldata);
				{$I+}
			end;
		end else begin
			with lldata do begin
				flag	:=false; logyear  :=0;
				logmonth:=0;	 logday   :=0;
				slogyear:=0;	 slogmonth:=0;
				slogday :=0;
			end;
			for INT:=0 to filesize(ids)+2 do begin
				{$I-}
				seek(llfile,int);
				write(llfile,lldata);
				{$I+}
			end;
		end;
	{$I-}
	close(ids);
	close(llfile);
	{$I+}
	end;
lllock  := false;
end.

