--[[

Kettler Boston XL Treadmill

--]]

local function handlestatusdata(data)

  if data==nil then
    return
  end

  local x = string.Split(data, "\t")

  if (x[8]==nil) then
    return nil;
  end

  local sd = {}

  sd.pulse = tonumber(x[1])

  sd.distance = tonumber(x[3])/100.0

  sd.energy = tonumber(x[5])

  sd.time = {}

  sd.time.minute=0;
  sd.time.second=0;
  sd.recovery=0;
  local tm = string.Split(x[6], ":")
  if (tm[2]==nil) then
    tm = string.Split(x[6], ";")
    if (tm[2]~=nil) then
      sd.time.minute=tonumber(tm[1])
      sd.time.second=tonumber(tm[2])
      sd.recovery=1;
    end
  else
    sd.time.minute=tonumber(tm[1])
    sd.time.second=tonumber(tm[2])
  end

  sd.elapsed = sd.time.minute*60+sd.time.second

  sd.actualspeed = tonumber(x[7])/10.0
  sd.actualincline =tonumber(x[8])

  sd.speedsetpoint = tonumber(x[2])/10.0
  sd.inclinesetpoint = tonumber(x[4])

  return sd
end

local device = serial.Classes.Queued:New({

  Name = "Kettler Treadmill",
  Description = "Kettler Boston XL Treadmill",

  BaudRate = 9600,
  Parity = 0,
  StopBits = 0, -- 0 = 1 stopbit.
  DataBits = 8,
  FlowControl = 'N',
  GlobalName = 'Kettler',
  IntraCharacterDelay = 0, --delay between characters

  CallbackType = serial.CB_FIXEDLENGTH,
  ReceiveFixedLength = 100,
  NoResponseTimeout = 1000,
  SendTerminator = '\r\n',
  IncompleteResponseTimeout = 100,
  LogLevel = False,

  Initialize = function (self)

    self.MyMutex = thread.newmutex ()

    self.Serial:RxClear()

    return serial.Classes.Queued.Initialize (self)

  end,

  RequestVersion = function (self)

    self.MyMutex:lock ()

    self:SendCommand ("VE")

    while self.ResponsePending do
      win.Sleep(50)
    end

    local reply = self.Reply

    self.MyMutex:unlock ()

    return reply

  end, -- 205 probably means firmware version

  RequestID = function (self)

    self.MyMutex:lock ()

    self:SendCommand ("ID")

    while self.ResponsePending do
      win.Sleep(50)
    end

    local reply = self.Reply

    self.MyMutex:unlock ()

    return reply

  end, -- BO2P   probably means boston xl ??

  RequestReset = function (self)

    self.MyMutex:lock ()

    self:SendCommand ("RS")

    while self.ResponsePending do
      win.Sleep(50)
    end

    local reply = self.Reply

    self.MyMutex:unlock ()

    return reply

  end, -- ACK

  -- command mode, without calling this first once, RequestSpeed/RequestIncline Don't work
  RequestCommandMode = function (self)

    self.MyMutex:lock ()

    self:SendCommand ("CM")

    while self.ResponsePending do
      win.Sleep(50)
    end

    local reply = self.Reply

    self.MyMutex:unlock ()

    return reply

  end, -- ACK

  --??? no idea what this one does
  RequestCA = function (self)

    self.MyMutex:lock ()

    self:SendCommand ("CA")

    while self.ResponsePending do
      win.Sleep(50)
    end

    local reply = self.Reply

    self.MyMutex:unlock ()

    return reply

  end, -- 103

  RequestStatus = function (self)

    self.MyMutex:lock ()

    self:SendCommand ("ST")

    while self.ResponsePending do
      win.Sleep(50)
    end

    local reply = self.Reply

    self.MyMutex:unlock ()

    return handlestatusdata (reply)

  end, -- 000    012    0023    02    0094    02:03    000    01
       -- pulse  spd*10 km*100  incl. energy  time     spd    incl.
       --        setp.          setp.                 current current

  RequestSpeed = function (self,speed)

    self.MyMutex:lock ()

    self:SendCommand ("PS "..tostring(math.round(speed*10)))

    while self.ResponsePending do
      win.Sleep(50)
    end

    local reply = self.Reply

    self.MyMutex:unlock ()

    return handlestatusdata (reply)

  end,

  RequestIncline = function (self,incline)

    self.MyMutex:lock ()

    self:SendCommand ("PI "..tostring(incline))

    while self.ResponsePending do
      win.Sleep(50)
    end

    local reply = self.Reply

    self.MyMutex:unlock ()

    return handlestatusdata (reply)
  end,

  ReceiveResponse = function ( self, data, code )

    if data ~= nil then
      data = string.gsub(data,"\r","");
      data = string.gsub(data,"\n","");
    end

    self.Reply = data;

    serial.Classes.Queued.ReceiveResponse (self,data,code)
  end,
}
)

serial.AddDevice (device)

