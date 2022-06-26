unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls,
  ExtCtrls, lNetComponents, Types, lNet;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    tcp: TLTCPComponent;
    StringGrid1: TStringGrid;
    StringGrid2: TStringGrid;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure StringGrid1Click(Sender: TObject);
    procedure StringGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure StringGrid2Click(Sender: TObject);
    procedure StringGrid2DrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure tcpConnect(aSocket: TLSocket);
    procedure tcpReceive(aSocket: TLSocket);
    procedure Timer1Timer(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;
  colorgrid1, colorgrid2, colorgrid3: array[0..10] of array[0..10] of uint8;
  x, health: uint8;
  timestamp: uint64;
  active_player: boolean;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.StringGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
begin
  case colorgrid1[acol, arow] of
  0: stringgrid1.canvas.brush.color:= rgbtocolor(0, 170, 255);
  1: stringgrid1.canvas.brush.color:= rgbtocolor(0, 255, 95);
  2: stringgrid1.canvas.brush.color:= rgbtocolor(186, 255, 0);
  3: stringgrid1.canvas.brush.color:= rgbtocolor(255, 185, 0);
  4: stringgrid1.canvas.brush.color:= rgbtocolor(255, 0, 155);
  5: stringgrid2.canvas.brush.color:= rgbtocolor(255, 0, 0);
  6: stringgrid2.canvas.brush.color:= rgbtocolor(50, 50, 50);
  end;
  stringgrid1.canvas.Rectangle(arect);
end;

procedure TForm1.StringGrid2Click(Sender: TObject);
begin
  if not active_player then
    exit;
  if colorgrid3[stringgrid2.col, stringgrid2.row] = 1 then
    exit;
  colorgrid3[stringgrid2.col, stringgrid2.row]:= 1;
  if colorgrid2[stringgrid2.col, stringgrid2.row] > 0 then
    dec(health);
  tcp.sendmessage('c' + inttostr(stringgrid2.col) + 'c' +  inttostr(stringgrid2.row));
  stringgrid2.repaint;
  active_player:= not active_player;
  label2.caption:= 'not active';
  if health = 0 then
  begin
    tcp.sendmessage('d');
    showmessage('you won');
    form1.color:= clgreen;
  end;
end;

procedure TForm1.StringGrid2DrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
begin
  if colorgrid3[acol, arow] = 1 then
    case colorgrid2[acol, arow] of
    0: stringgrid2.canvas.brush.color:= rgbtocolor(0, 170, 255);
    1: stringgrid2.canvas.brush.color:= rgbtocolor(0, 255, 95);
    2: stringgrid2.canvas.brush.color:= rgbtocolor(186, 255, 0);
    3: stringgrid2.canvas.brush.color:= rgbtocolor(255, 185, 0);
    4: stringgrid2.canvas.brush.color:= rgbtocolor(255, 0, 155);
    end
  else
    stringgrid2.canvas.brush.color:= rgbtocolor(50, 50, 50);
  stringgrid2.canvas.Rectangle(arect);
end;

procedure TForm1.tcpConnect(aSocket: TLSocket);
var
  s: string;
  i, i2: uint64;
begin
  form1.color:= clgreen;
  timer1.Enabled:= true;
  s:= 'a';
  for i:= 0 to 10 do
    for i2:= 0 to 10 do
      s:= s + inttostr(colorgrid1[i, i2]);
  tcp.SendMessage(s);
end;

procedure TForm1.tcpReceive(aSocket: TLSocket);
var
  s: string;
  i, i2, i3: uint64;
begin
  i3:= 2;
  tcp.GetMessage(s);
  if length(s) = 0 then
    exit;
  if s[1] = 'a' then
    for i:= 0 to 10 do
      for i2:= 0 to 10 do
      begin
        colorgrid2[i, i2]:= strtoint(s[i3]);
        inc(i3);
        tcp.sendmessage('b' + inttostr(timestamp));
      end;
  if s[1] = 'b' then
    if timestamp < strtoint(s.Split('b')[1]) then
    begin
      active_player:= true;
      label2.caption:= 'active';
    end
    else
    begin
      active_player:= false;
      label2.caption:= 'not active';
    end;
  if s[1] = 'c' then
  begin
    if colorgrid1[strtoint(s.Split('c')[1]), strtoint(s.Split('c')[2])] > 0 then
      colorgrid1[strtoint(s.Split('c')[1]), strtoint(s.Split('c')[2])]:= 5
    else
      colorgrid1[strtoint(s.Split('c')[1]), strtoint(s.Split('c')[2])]:= 6;
    stringgrid1.repaint;
    active_player:= not active_player;
    label2.caption:= 'active';
  end;
  if s[1] = 'd' then
  begin
    showmessage('You lost');
    form1.color:= clred;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  form1.color:= clgray;
  timer1.enabled:= false;
end;

procedure TForm1.StringGrid1Click(Sender: TObject);
begin
  if x < 4 then
  begin
    if colorgrid1[stringgrid1.Col, stringgrid1.row] > 0 then
      exit;
    colorgrid1[stringgrid1.Col, stringgrid1.row]:= 1;
    inc(x);
  end
  else
  if x < 7 then
  begin
    if checkbox1.Checked then
    begin
      if (stringgrid1.row < 1) or (stringgrid1.col > 9) or (stringgrid1.col < 1) then
        exit;
      if (colorgrid1[stringgrid1.Col, stringgrid1.row] > 0) or (colorgrid1[stringgrid1.Col + 1, stringgrid1.row] > 0) then
        exit;
      colorgrid1[stringgrid1.Col, stringgrid1.row]:= 2;
      colorgrid1[stringgrid1.Col + 1, stringgrid1.row]:= 2;
    end
    else
    begin
      if (stringgrid1.row < 1) or (stringgrid1.row > 9) or (stringgrid1.col < 1) then
        exit;
      if (colorgrid1[stringgrid1.Col, stringgrid1.row] > 0) or (colorgrid1[stringgrid1.Col, stringgrid1.row + 1] > 0) then
        exit;
      colorgrid1[stringgrid1.Col, stringgrid1.row]:= 2;
      colorgrid1[stringgrid1.Col, stringgrid1.row + 1]:= 2;
    end;
    inc(x);
  end
  else
  if x < 9 then
  begin
    if checkbox1.Checked then
    begin
      if (stringgrid1.row < 1) or (stringgrid1.col > 8) or (stringgrid1.col < 1) then
        exit;
      if (colorgrid1[stringgrid1.Col, stringgrid1.row] > 0) or (colorgrid1[stringgrid1.Col + 1, stringgrid1.row] > 0) or (colorgrid1[stringgrid1.Col + 2, stringgrid1.row] > 0) then
        exit;
      colorgrid1[stringgrid1.Col, stringgrid1.row]:= 3;
      colorgrid1[stringgrid1.Col + 1, stringgrid1.row]:= 3;
      colorgrid1[stringgrid1.Col + 2, stringgrid1.row]:= 3;
    end
    else
    begin
      if (stringgrid1.row < 1) or (stringgrid1.row > 8) or (stringgrid1.col < 1) then
        exit;
      if (colorgrid1[stringgrid1.Col, stringgrid1.row] > 0) or (colorgrid1[stringgrid1.Col, stringgrid1.row + 1] > 0) or (colorgrid1[stringgrid1.Col, stringgrid1.row + 2] > 0) then
        exit;
      colorgrid1[stringgrid1.Col, stringgrid1.row]:= 3;
      colorgrid1[stringgrid1.Col, stringgrid1.row + 1]:= 3;
      colorgrid1[stringgrid1.Col, stringgrid1.row + 2]:= 3;
    end;
    inc(x);
  end
  else
  if x = 9 then
  begin
    if checkbox1.Checked then
    begin
      if (stringgrid1.row < 1) or (stringgrid1.col > 7) or (stringgrid1.col < 1) then
        exit;
      if (colorgrid1[stringgrid1.Col, stringgrid1.row] > 0) or (colorgrid1[stringgrid1.Col + 1, stringgrid1.row] > 0) or (colorgrid1[stringgrid1.Col + 2, stringgrid1.row] > 0) or (colorgrid1[stringgrid1.Col + 3, stringgrid1.row] > 0) then
        exit;
      colorgrid1[stringgrid1.Col, stringgrid1.row]:= 4;
      colorgrid1[stringgrid1.Col + 1, stringgrid1.row]:= 4;
      colorgrid1[stringgrid1.Col + 2, stringgrid1.row]:= 4;
      colorgrid1[stringgrid1.Col + 3, stringgrid1.row]:= 4;
    end
    else
    begin
      if (stringgrid1.row < 1) or (stringgrid1.row > 7) or (stringgrid1.col < 1) then
        exit;
      if (colorgrid1[stringgrid1.Col, stringgrid1.row] > 0) or (colorgrid1[stringgrid1.Col, stringgrid1.row + 1] > 0) or (colorgrid1[stringgrid1.Col, stringgrid1.row + 2] > 0) or (colorgrid1[stringgrid1.Col, stringgrid1.row + 3] > 0) then
        exit;
      colorgrid1[stringgrid1.Col, stringgrid1.row]:= 4;
      colorgrid1[stringgrid1.Col, stringgrid1.row + 1]:= 4;
      colorgrid1[stringgrid1.Col, stringgrid1.row + 2]:= 4;
      colorgrid1[stringgrid1.Col, stringgrid1.row + 3]:= 4;
    end;
    inc(x);
    tcp.listen(60000);
    timestamp:= gettickcount64;
  end;
  stringgrid1.repaint;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  health:= 20;
  edit1.clear;
  form1.color:= clgray;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if x < 10 then
    exit;
  tcp.connect(edit1.text, 60000);
end;

end.

