unit FirstTest;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, WinSCard, WinSmCrd, SCardErr,
  StdCtrls, PCSCConnector;

type
  TForm1 = class(TForm)
    pcsc: TPCSCConnector;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    bt_Init: TButton;
    bt_Open: TButton;
    bt_Connect: TButton;
    bt_Close: TButton;
    bt_Disconnect: TButton;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    bt_Send: TButton;
    Memo1: TMemo;
    Label13: TLabel;
    Label14: TLabel;
    Button1: TButton;
    procedure pcscCardRemoved(Sender: TObject);
    procedure pcscError(Sender: TObject; ErrSource: TErrSource; ErrCode: Cardinal);
    procedure ShowData;
    procedure bt_InitClick(Sender: TObject);
    procedure bt_OpenClick(Sender: TObject);
    procedure bt_ConnectClick(Sender: TObject);
    procedure bt_CloseClick(Sender: TObject);
    procedure bt_DisconnectClick(Sender: TObject);
    procedure bt_SendClick(Sender: TObject);
    procedure pcscCardActive(Sender: TObject);
    procedure pcscCardInserted(Sender: TObject);
    procedure pcscCardInvalid(Sender: TObject);
    procedure pcscReaderConnect(Sender: TObject);
    procedure pcscReaderDisconnect(Sender: TObject);
    procedure pcscReaderListChange(Sender: TObject);
    procedure pcscReaderWaiting(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

const

HexChars    = '0123456789abcdefABCDEF';

procedure ListSmartCardReaders(Memo: TMemo);
var
  hContext: cardinal;
  Readers: PChar;
  ReaderList: TStringList;
  ReaderListSize: integer;
  Res: LongInt;
  PtrReader: PChar;
  qt:LongInt;
begin
  Memo.Clear; // Limpa o memo antes de adicionar os leitores
  Readers := nil;
  ReaderListSize := 0;
  ReaderList := TStringList.Create;

  try
    // Estabelece o contexto para comunica��o com o gerenciador de smartcard
    Res := SCardEstablishContext(SCARD_SCOPE_USER, nil, nil, @hContext);
    if Res <> SCARD_S_SUCCESS then
    begin
      Memo.Lines.Add('Erro ao estabelecer contexto: ' + IntToStr(Res));
      Exit;
    end;

    // Obt�m o tamanho necess�rio para armazenar os leitores
    Res := SCardListReadersW(hContext, nil,nil, ReaderListSize);
//    RetVar := SCardListReadersA(FContext, nil, nil, ReaderListSize);
    if (Res <> SCARD_S_SUCCESS) or (ReaderListSize = 0) then
    begin
      Memo.Lines.Add('Nenhum leitor encontrado ou erro: ' + IntToStr(Res));
      Exit;
    end;

    // Aloca espa�o para armazenar a lista de leitores
    GetMem(Readers, ReaderListSize);

    try
      // Obt�m a lista de leitores
      Res := SCardListReadersW(hContext, nil, Pointer(Readers), ReaderListSize);
//             SCardListReadersA(FContext, nil, Pointer(ReaderList), ReaderListSize);
      if Res <> SCARD_S_SUCCESS then
      begin
        Memo.Lines.Add('Erro ao listar leitores: ' + IntToStr(Res));
        Exit;
      end;

      // Adiciona os leitores � lista
      PtrReader := Readers;
      while PtrReader^ <> #0 do
      begin
        ReaderList.Add(PtrReader);
        Inc(PtrReader, StrLen(PtrReader) + 1);
      end;

      // Exibe os leitores no TMemo
      Memo.Lines.AddStrings(ReaderList);
    finally
      FreeMem(Readers);
    end;

  finally
    // Libera o contexto
    SCardReleaseContext(hContext);
    ReaderList.Free;
  end;
end;

function Hex2Bin(input: string): string;
var
hex, output: string;
loop       : integer;
begin
     for loop := 1 to Length(input) do if Pos(input[loop], hexchars) > 0 then hex := hex + AnsiUpperCase(input[loop]);
     loop := 1;
     if Length(hex) > 0 then
        repeat
        output := output + Chr(StrToInt('$'+Copy(hex,loop,2)));
        loop := loop + 2;
        until loop > Length(hex);
     Result := output;
end;

function Bin2HexExt(const input:string; const spaces, upcase: boolean): string;
var
   loop      : integer;
   hexresult : string;
begin
     hexresult := '';
     for loop := 1 to Length(input) do
        begin
        hexresult := hexresult + IntToHex(Ord(input[loop]),2);
        if spaces then hexresult := hexresult + ' ';
        end;
     if upcase then result := AnsiUpperCase(hexresult)
               else result := AnsiLowerCase(hexresult);
end;

function AnsiToWide(const AnsiStr: AnsiString; CodePage: Cardinal = CP_ACP ): WideString;
var
  Len: Integer;
  AnsiReader: AnsiString;
begin
  Len := MultiByteToWideChar(CodePage, 0, PAnsiChar(AnsiStr), -1, nil, 0);
  SetLength(Result, Len - 1);
  MultiByteToWideChar(CodePage, 0, PAnsiChar(AnsiStr), -1, PWideChar(Result), Len);
end;

procedure TForm1.ShowData;
begin
label3.caption := IntToHex(pcsc.ReaderState,8);
label4.caption := pcsc.AttrICCType;
label5.caption := pcsc.AttrVendorName;
label6.caption := pcsc.AttrVendorSerial;
label14.caption := IntToHex(pcsc.AttrProtocol,8)+' ATR:'+Bin2HexExt(pcsc.AttrCardATR,true,true);

end;

procedure TForm1.pcscCardRemoved(Sender: TObject);
begin
memo1.Lines.Add('OnCardRemoved');
ShowData;
end;

procedure TForm1.pcscError(Sender: TObject; ErrSource: TErrSource; ErrCode: Cardinal);
begin
if memo1.Lines[memo1.Lines.Count-1]='OnError ' + IntToHex(ErrCode,8) then exit;
memo1.Lines.Add('OnError ' + IntToHex(ErrCode,8));
label1.caption := IntToHex(ErrCode,8);
ShowData;
end;


procedure TForm1.bt_InitClick(Sender: TObject);
var i:integer;
begin
pcsc.Init;
pcsc.UseReaderNum := 0;
end;


procedure TForm1.bt_OpenClick(Sender: TObject);
begin
if pcsc.Open then memo1.lines.add('OPEN: OK')
             else memo1.lines.add('OPEN: NOT OK');
end;

procedure TForm1.bt_ConnectClick(Sender: TObject);
begin
if pcsc.Connect then memo1.lines.add('CONNECT to ''' + IntToStr(pcsc.UseReaderNum) + ''' : OK')
                else memo1.lines.add('CONNECT to ''' + IntToStr(pcsc.UseReaderNum) + ''' : NOT OK');
end;

procedure TForm1.bt_CloseClick(Sender: TObject);
begin
pcsc.Close;
end;

procedure TForm1.bt_DisconnectClick(Sender: TObject);
begin
pcsc.Disconnect;
end;

procedure TForm1.bt_SendClick(Sender: TObject);
begin
   label2.caption := Bin2HexExt(pcsc.GetResponseFromCard(Hex2Bin('a0f2000016')), true, true);
end;

procedure TForm1.Button1Click(Sender: TObject);
var i:integer;
begin
   memo1.Lines.Add(inttostr(pcsc.ReaderList.Count));
   for i:=0 to pcsc.ReaderList.Count-1 do begin
      memo1.Lines.Add(inttostr(i)+':'+pcsc.ReaderList[i]);
   end;
end;

procedure TForm1.pcscCardActive(Sender: TObject);
begin
   memo1.Lines.Add('OnCardActive');
   ShowData;
end;

procedure TForm1.pcscCardInserted(Sender: TObject);
begin
memo1.Lines.Add('OnCardInserted');
ShowData;
end;

procedure TForm1.pcscCardInvalid(Sender: TObject);
begin
memo1.Lines.Add('OnCardInvalid');
ShowData;
end;

procedure TForm1.pcscReaderConnect(Sender: TObject);
begin
memo1.Lines.Add('OnReaderConnect');
ShowData;
end;

procedure TForm1.pcscReaderDisconnect(Sender: TObject);
begin
memo1.Lines.Add('OnReaderDisconnect');
ShowData;
end;

procedure TForm1.pcscReaderListChange(Sender: TObject);
begin
memo1.Lines.Add('OnReaderListChange');
end;

procedure TForm1.pcscReaderWaiting(Sender: TObject);
begin
memo1.Lines.Add('OnReaderWaiting');
end;

end.

