{$M 4096, 0, 0}
{$G+}
uses
  DOS;

type
  tsound = record
    key: byte;
    note: word;
  end;

const
  MaxSoundPeriod = 5;
  MaxLightPeriod = 5;
  numsound = 24;
  sound: array[1..numsound] of tsound = (
    (key:$2C; note:$11D0),(key:$2D; note:$0FDF),(key:$2E; note:$0E23),
    (key:$2F; note:$0D58),(key:$30; note:$0BE3),(key:$31; note:$0A97),
    (key:$32; note:$096F),(key:$1F; note:$10D0),(key:$20; note:$0EFA),
    (key:$22; note:$0C98),(key:$23; note:$0B39),(key:$24; note:$09FF),
    (key:$10; note:$08E8),(key:$11; note:$07EF),(key:$12; note:$0711),
    (key:$13; note:$06AC),(key:$14; note:$05F1),(key:$15; note:$054B),
    (key:$16; note:$04B8),(key:$03; note:$0868),(key:$04; note:$077D),
    (key:$06; note:$064C),(key:$07; note:$059C),(key:$08; note:$04FF)
  );

var
  OldTimerIntVect, OldKeyboardIntVect: procedure;
  SoundPeriod, LightPeriod: integer;
  switch: boolean;

procedure Wait; near; assembler;
asm
  xor cx, cx
@Wait:
  in al, 64h
  and al, 00000010b
  loopnz @Wait
end;

procedure NoSound; assembler;
asm
  in al, 61h
  and al, 11111100b
  out 61h, al
end;

procedure NewTimerIntVect; interrupt; assembler;
asm
  mov ax, SoundPeriod
  or ax, ax
  jle @watchLight
  dec SoundPeriod
  jnz @watchLight
  call NoSound

@watchLight:
  mov ax, LightPeriod
  or ax, ax
  jle @exit
  dec LightPeriod
  jnz @exit
  mov LightPeriod, MaxLightPeriod
  xor ax, ax
  mov es, ax
  mov bl, 0
  xor switch, true
  jz @SetLampState
  mov bl, [es:0417h]
  shr bl, 4
  and bl, 111b

@SetLampState:
  call Wait
  mov al, 0EDh
  out 60h, al
  call Wait
  mov al, bl
  out 60h, al

@exit:
  pushf
  call OldTimerIntVect
end;

procedure NewKeyboardIntVect; interrupt; assembler;
asm
  in al, 60h
  lea si, sound
  mov cx, numsound

@compare:
  mov dl, [si+tsound.key]
  cmp al, dl
  je @playSound
  add si, type(tsound)
  loop @compare
  jmp @exit

@playSound:
  mov al, 0b6h
  out 43h, al
  mov dx, [si+tsound.note]
  mov al, dl
  out 42h, al
  mov al, dh
  out 42h, al
  in al, 61h
  or al, 00000011b
  out 61h, al
  mov SoundPeriod, MaxSoundPeriod
@exit:
  pushf
  call OldKeyboardIntVect
end;

begin
  SoundPeriod := MaxSoundPeriod;
  LightPeriod := MaxLightPeriod;
  GetIntVec(8, @OldTimerIntVect);
  SetIntVec(8, @NewTimerIntVect);
  GetIntVec(9, @OldKeyboardIntVect);
  SetIntVec(9, @NewKeyboardIntVect);
  readln;
  Keep(0);
end.