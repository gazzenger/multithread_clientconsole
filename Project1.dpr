program Project1;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ScktComp, extctrls, Windows, System, Dialogs;

type
  TEventHandlers = class
    procedure OnConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure OnDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure OnRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure OnError(Sender: TObject;Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;var ErrorCode: Integer);
  end;

var
  ClientSocket1: TClientSocket;
  EventHandlers: TEventHandlers;
  LocalHost: string;
  QuitProg : boolean;
  filename : string;
  project: string;
  autostart: boolean;


procedure TEventHandlers.OnConnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  //Writeln('Status: Connected with ' + ClientSocket1.Socket.RemoteHost);
  LocalHost := Socket.LocalHost;
      //write to the server
  if not autostart then
    ClientSocket1.Socket.SendText('[' + DatetoStr(Date) + ' ' + TimetoStr(GetTime) + '] ' + LocalHost + ': ' + 'proj=' + project + 'file=' + filename)
    else
    ClientSocket1.Socket.SendText('[' + DatetoStr(Date) + ' ' + TimetoStr(GetTime) + '] ' + LocalHost + ': /autostart' + 'proj=' + project + 'file=' + filename);

end;

procedure TEventHandlers.OnDisconnect(Sender: TObject; Socket: TCustomWinSocket);
begin
  Writeln('Status: Disconnected.');
end;

procedure TEventHandlers.OnRead(Sender: TObject; Socket: TCustomWinSocket);

var
  read: string;
  projpos: integer;
  filepos: integer;
  project: string;
begin
  read := socket.ReceiveText;
  Writeln(read);
  if (pos('queued', read) <> 0) or (pos('Error', read) <> 0) then
  begin
    //close the port
    ClientSocket1.Active := false;
    ClientSocket1.Destroy;
    QuitProg := true
  end;
end;

procedure TEventHandlers.OnError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
    Writeln('An Error has occured whilst trying to connect, recheck the server name and port number.');
    QuitProg := true;
    ErrorCode := 0;
end;


procedure MsgPump;
var
  Unicode: Boolean;
  Msg: TMsg;

begin
while not (QuitProg) do
  if GetMessage(Msg, 0, 0, 0) then
  begin

    begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end

  end;

end;


function ConvertToUNCPath
  (MappedDrive: string): string;
var
  RemoteString: array[0..255] of char;
  lpRemote: PChar;
  StringLen: Cardinal;
begin
  if (MappedDrive[1] = '\') and (MappedDrive[2] = '\') and FileExists(MappedDrive) then
    Result := MappedDrive
  else
  begin
    lpRemote := @RemoteString;
    StringLen := 255;
    if WNetGetConnection(Pchar(ExtractFileDrive(MappedDrive)), lpRemote, StringLen) = NO_ERROR then
    begin
      if FileExists(RemoteString + copy(MappedDrive, 3, length(MappedDrive) - 2)) then
        Result := RemoteString + copy(MappedDrive, 3, length(MappedDrive) - 2)
      else
        Result := '';
    end
    else
      Result := '';
  end;
end;



begin
  { TODO -oUser -cConsole Main : Insert code here }
  QuitProg := false;
  if (ParamStr(1) = '') then
  begin
    Write('No Host IP Address Given');
    exit;
  end
  else if (ParamStr(2) = '') then
  begin
    Write('No Port Number Given');
    exit;
  end
  else if (ParamStr(3) = '') then
  begin
    Write('No input file given');
    exit;
  end
    else if (ParamStr(4) = '') then
  begin
    Write('No project file given');
    exit;
  end;

      filename := ConvertToUNCPath(GetCurrentDir+'\'+ParamStr(3));
    //if filename = '' then exit;

    project := ParamStr(4);

    autostart := (ParamStr(5) = 'autostart');


  EventHandlers := TEventHandlers.Create();
  ClientSocket1 := TClientSocket.Create(nil);

  with ClientSocket1 do
  begin
    Address := '';
    ClientType := ctNonBlocking;
    Host := ParamStr(1);
    Port := strtoint(ParamStr(2));
    Service := '';
    Tag := 0;
    OnConnect := EventHandlers.OnConnect;
    OnDisconnect := EventHandlers.OnDisconnect;
    OnRead := EventHandlers.OnRead;
    OnError := EventHandlers.OnError;
    Active := true;
  end;


  MsgPump;






  Writeln('...Finished');


end.

