{..............................................................................}
{ Summary   This Script creates fillet on selected tracks                      }
{                                                                              }
{           Radius value = (shorter of two lines) * 0,5 * Slider Position      }
{                                                                              }
{ Created by:    Petar Perisin                                                 }
{..............................................................................}

{..............................................................................}
var
   Board         : IPCB_Board;
   MinDistance   : Double;

   (* I need string list to memorize radius of each track.
   Since arc is added betwen two tracks, I will need to find lesser value of the two

   Data will be stored in stringlist in order:
   I_ObjectAdress1;radius1
   I_ObjectAdress2;radius2
   ....
   ....
   I_ObjectAdressN;radiusN
   *)
   RadiusList     : TStringList;





procedure TForm1.ButtonOKClick(Sender: TObject);
var
    FirstTrack    : IPCB_Primitive;
    SecondTrack   : IPCB_Primitive;
    XCommon       : Integer;
    YCommon       : Integer;  
    angle1        : Double;
    angle2        : Double;
    Radius        : Integer;
    k1            : Double;
    k2            : Double;
    FirstCommon   : Integer;
    SecondCommon  : Integer;
    Xc            : Integer;
    Yc            : Integer;
    i, j          : integer;
    flag          : integer;
    X1, X2, Y1, Y2: Integer;
    StartAngle    : Double;
    StopAngle     : Double;
    Arc           : IPCB_Arc;
    Line          : String;
    ObjAdr        : Integer;
    Leng          : Integer;

    a, b          : Integer;
begin
   PCBServer.PreProcess;
   For a := 0 to Board.SelectecObjectCount - 1 do
   begin
      FirstTrack := Board.SelectecObject[a];
      for b := 0 to Board.SelectecObjectCount - 1 do
      begin
         SecondTrack := Board.SelectecObject[b];
         if (FirstTrack.ObjectId = eTrackObject) and (SecondTrack.ObjectId = eTrackObject) and (a <> b) and
         (SecondTrack.Layer = FirstTrack.Layer) and (
         ((SecondTrack.x1 = FirstTrack.x1) and (SecondTrack.y1 = FirstTrack.y1)) or
         ((SecondTrack.x2 = FirstTrack.x1) and (SecondTrack.y2 = FirstTrack.y1)) or
         ((SecondTrack.x2 = FirstTrack.x2) and (SecondTrack.y2 = FirstTrack.y2)) or
         ((SecondTrack.x1 = FirstTrack.x2) and (SecondTrack.y1 = FirstTrack.y2))) then
         begin

            // Here we are and two tracks are connected. now I need to check the point in common.
            if (SecondTrack.x1 = FirstTrack.x1) and (SecondTrack.y1 = FirstTrack.y1) then
            begin
               XCommon := FirstTrack.x1;
               YCommon := FirstTrack.y1;
               FirstCommon  := 1;
               SecondCommon := 1;
            end
            else if (SecondTrack.x2 = FirstTrack.x1) and (SecondTrack.y2 = FirstTrack.y1) then
            begin
               XCommon := FirstTrack.x1;
               YCommon := FirstTrack.y1;
               FirstCommon  := 1;
               SecondCommon := 2;
            end
            else if (SecondTrack.x2 = FirstTrack.x2) and (SecondTrack.y2 = FirstTrack.y2) then
            begin
               XCommon := FirstTrack.x2;
               YCommon := FirstTrack.y2;
               FirstCommon  := 2;
               SecondCommon := 2;
            end
            else if (SecondTrack.x1 = FirstTrack.x2) and (SecondTrack.y1 = FirstTrack.y2) then
            begin
               XCommon := FirstTrack.x2;
               YCommon := FirstTrack.y2;
               FirstCommon  := 2;
               SecondCommon := 1;
            end;

            // now the angles of FirstTrack
            if FirstCommon = 1 then
            begin
               // First point is common
               if FirstTrack.x2 = FirstTrack.x1 then
               begin
                  if FirstTrack.y1 > FirstTrack.y2 then Angle1 := 3 * PI / 2
                  else                                  Angle1 := PI / 2;
               end
               else
                  Angle1 := arctan((FirstTrack.y2 - FirstTrack.y1)/(FirstTrack.x2 - FirstTrack.x1));
               if FirstTrack.x2 < FirstTrack.x1 then Angle1 := Angle1 + pi;
            end
            else
            begin
               // Second point is common
               if FirstTrack.x2 = FirstTrack.x1 then
               begin
                  if FirstTrack.y1 < FirstTrack.y2 then Angle1 := 3 * PI / 2
                  else                                  Angle1 := PI / 2;
               end
               else
                  Angle1 := arctan((FirstTrack.y1 - FirstTrack.y2)/(FirstTrack.x1 - FirstTrack.x2));
               if FirstTrack.x1 < FirstTrack.x2 then Angle1 := Angle1 + pi;
            end;

            if Angle1 < 0 then Angle1 := 2 * pi + Angle1;

            // now the angles of SecondTrack
            if SecondCommon = 1 then
            begin
               // First point is common
               if SecondTrack.x2 = SecondTrack.x1 then
                begin
                  if SecondTrack.y1 > SecondTrack.y2 then Angle2 := 3 * PI / 2
                  else                                    Angle2 := PI / 2;
               end
               else
                  Angle2 := arctan((SecondTrack.y2 - SecondTrack.y1)/(SecondTrack.x2 - SecondTrack.x1));
               if SecondTrack.x2 < SecondTrack.x1 then Angle2 := Angle2 + pi;
            end
            else
            begin
               // Second point is common
               if SecondTrack.x2 = SecondTrack.x1 then
               begin
                  if SecondTrack.y1 < SecondTrack.y2 then Angle2 := 3 * PI / 2
                  else                                    Angle2 := PI / 2;
               end
               else
                  Angle2 := arctan((SecondTrack.y1 - SecondTrack.y2)/(SecondTrack.x1 - SecondTrack.x2));
               if SecondTrack.x1 < SecondTrack.x2 then Angle2 := Angle2 + pi;
            end;

            if Angle2 < 0 then Angle2 := 2 * pi + Angle2;

            // Now we need to check weather we will be placing any arcs
            if not ((Angle1 = Angle2) or
               ((Angle1 > Angle2) and (Angle1 - PI = Angle2)) or
               ((Angle1 < Angle2) and (Angle2 - PI = Angle1))) then
               begin

                  i := 0;
                  flag := 0;

                  while i < RadiusList.Count do
                  begin
                     Line := RadiusList[i];
                     j := LastDelimiter(';', Line);

                     ObjAdr := StrToInt(Copy(Line, 1, j-1));
                     Leng   := Int(StrToInt(Copy(Line, j+1, length(Line))) * ScrollBarPerc.Position / 100);

                     // ShowMessage(Line + ' ' + Copy(Line, 1, j-1) + ' ' + Copy(Line, j+1, length(Line)) + ' ' + IntToStr(FirstTrack.I_ObjectAddress) + ' ' + IntToStr(SecondTrack.I_ObjectAddress));

                     if (ObjAdr = FirstTrack.I_ObjectAddress) then
                     begin
                        if flag = 0 then           Radius := Leng
                        else if Radius > Leng then Radius := Leng;
                        flag := 1;
                     end;

                     if (ObjAdr = SecondTrack.I_ObjectAddress) then
                     begin
                        if flag = 0 then           Radius := Leng
                        else if Radius > Leng then Radius := Leng;
                        flag := 1;
                     end;
                     Inc(i);
                  end;

                  // modify point of FirstTrack
                  if FirstCommon = 1 then
                  begin
                     FirstTrack.x1 := FirstTrack.x1 + Radius*cos(Angle1);
                     FirstTrack.y1 := FirstTrack.y1 + Radius*sin(Angle1);
                     X1 := FirstTrack.x1;
                     Y1 := FirstTrack.y1;
                  end
                  else
                  begin
                     FirstTrack.x2 := FirstTrack.x2 + Radius*cos(Angle1);
                     FirstTrack.y2 := FirstTrack.y2 + Radius*sin(Angle1);
                     X1 := FirstTrack.x2;
                     Y1 := FirstTrack.y2;
                  end;

                  if Angle1 < 0 then Angle1 := pi + Angle1;

                  // modify point of SecondTrack
                  if SecondCommon = 1 then
                  begin
                     SecondTrack.x1 := SecondTrack.x1 + Radius*cos(Angle2);
                     SecondTrack.y1 := SecondTrack.y1 + Radius*sin(Angle2);
                     X2 := SecondTrack.x1;
                     Y2 := SecondTrack.y1;
                  end
                  else
                  begin
                     SecondTrack.x2 := SecondTrack.x2 + Radius*cos(Angle2);
                     SecondTrack.y2 := SecondTrack.y2 + Radius*sin(Angle2);
                     X2 := SecondTrack.x2;
                     Y2 := SecondTrack.y2;
                  end;

                  // Calculate X center of arc
                  if      ((Angle1 = 0) or (Angle1 = pi)) then Xc := X1
                  else if ((Angle2 = 0) or (Angle2 = pi)) then Xc := X2
                  else
                  begin
                     k1 := tan(pi/2 + Angle1);
                     k2 := tan(pi/2 + Angle2);

                     Xc := (Y2 - Y1 + k1 * X1 - k2 * X2) / (k1 - k2);
                  end;

                  // Calculate Y center of
                  if      ((Angle1 = Pi / 2) or (Angle1 = pi * 3 / 2)) then
                     Yc := Y1
                  else if ((Angle2 = Pi / 2) or (Angle2 = pi * 3 / 2)) then
                     Yc := Y2
                  else
                  begin
                     if ((Angle1 <> 0) and (Angle1 <> pi))      then Yc := tan(pi/2 + Angle1) * (Xc - X1) + Y1
                     else if ((Angle2 <> 0) and (Angle2 <> pi)) then Yc := tan(pi/2 + Angle2) * (Xc - X2) + Y2;
                  end;

                  // now we need to see what is first angle and what is second angle of an arc
                  if      ((Angle1 > Angle2) and (Angle1 - Angle2 < Pi)) then
                  begin
                     StartAngle := Pi / 2 +  Angle1;
                     StopAngle  := 3 * PI / 2 + Angle2;
                  end
                  else if ((Angle1 > Angle2) and (Angle1 - Angle2 > Pi)) then
                  begin
                     StartAngle := Pi / 2 +  Angle2;
                     StopAngle  := Angle1 - Pi / 2;
                  end
                  else if ((Angle1 < Angle2) and (Angle2 - Angle1 < Pi)) then
                  begin
                     StartAngle := Pi / 2 +  Angle2;
                     StopAngle  := 3 * PI / 2 + Angle1;
                  end
                  else if ((Angle1 < Angle2) and (Angle2 - Angle1 > Pi)) then
                  begin
                     StartAngle := Pi / 2 +  Angle1;
                     StopAngle  := Angle2 - Pi / 2;
                  end;

                  // Count radius - I have no idea why


                  Arc := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
                  Arc.XCenter    := Int(Xc);
                  Arc.YCenter    := Int(Yc);
                  Arc.Radius     := sqrt(sqr(X1 - Xc) + sqr(Y1 - Yc));;
                  Arc.LineWidth  := FirstTrack.Width;
                  Arc.StartAngle := StartAngle * 180 / pi;
                  Arc.EndAngle   := StopAngle * 180 / pi;
                  Arc.Layer      := FirstTrack.Layer;
                  if FirstTrack.InNet then Arc.Net := FirstTrack.Net;
                  Board.AddPCBObject(Arc);
                  Arc.Selected   := False;

                  Board.DispatchMessage(Board.I_ObjectAddress, c_Broadcast, PCBM_BoardRegisteration, FirstTrack.I_ObjectAddress);
                  Board.DispatchMessage(Board.I_ObjectAddress, c_Broadcast, PCBM_BoardRegisteration, SecondTrack.I_ObjectAddress);
                  Board.DispatchMessage(Board.I_ObjectAddress, c_Broadcast, PCBM_BoardRegisteration, Arc.I_ObjectAddress);

            end;
         end;
      end;
   end;

   PCBServer.PostProcess;

   RadiusList.Clear;

   If ScrollBarPerc.Position = 100 then
   begin
      for i := 0 to Board.SelectecObjectCount - 1 do
      begin
         FirstTrack := Board.SelectecObject[i];
         if ((FirstTrack.x1 = FirstTrack.x2) and (FirstTrack.y1 = FirstTrack.y2)) then RadiusList.AddObject(FirstTrack.I_ObjectAddress, FirstTrack);
      end;

      for i := 0 to Radiuslist.Count - 1 do
         Board.RemovePCBObject(RadiusList.GetObject(i));
   end;

   
   ResetParameters;
   AddStringParameter('Scope', 'All');
   RunProcess('PCB:DeSelect');

   ResetParameters;
   AddStringParameter('Action', 'Redraw');
   RunProcess('PCB:Zoom');

   close;
end;


procedure TForm1.ScrollBarPercChange(Sender: TObject);
begin
   LabelValue.Caption := IntToStr(ScrollBarPerc.Position);
   if ScrollBarPerc.Position <> 0 then
      LabelRadius.Caption := FloatToStr(CoordToMMs(Int(MinDistance * ScrollBarPerc.Position / 100))) + ' mm'
   else
      LabelRadius.Caption := '0 mm';
end;


procedure Start;
var
    Track     : IPCB_Primitive;
    Leng      : Integer;
    Flag      : Integer;
    i         : Integer;
    Distance  : Double;

begin
    Board := PCBServer.GetCurrentPCBBoard;
    If Board = Nil Then Exit;

    flag := 0;
    RadiusList := TStringList.Create;

    for i := 0 to Board.SelectecObjectCount - 1 do
    begin
       Track := Board.SelectecObject[i];
       (*
       if Track.ObjectID <> eTrackObject then
       begin
          showMessage('Select only Tracks');
          exit;
       end;  *)

       Leng := Int(sqrt(sqr(Track.x2 - Track.x1) + sqr(Track.y2 - Track.y1)) * 0.5);
       RadiusList.Add(IntToStr(Track.I_ObjectAddress) + ';' + IntToStr(Leng));

       flag := 1;
    end;

    If flag = 0 then
    begin
       showMessage('No Selected Tracks');
       exit;
    end;

    MinDistance := -1;
    for i := 1 to Board.SelectecObjectCount - 1 do
    begin
       if Track.ObjectID <> eTrackObject then
       begin
          Distance := sqrt(sqr(Board.SelectecObject[i].x1 - Board.SelectecObject[i].x2) + sqr(Board.SelectecObject[i].y1 - Board.SelectecObject[i].y2));

          if (Distance < Mindistance) or (MinDistance = -1) then Mindistance := Distance;
       end
    end;

    Mindistance := MinDistance / 2;

    LabelRadius.Caption := FloatToStr(CoordToMMs(Int(MinDistance / 2))) + ' mm';

    Form1.ShowModal;
end;


procedure TForm1.ButtonCancelClick(Sender: TObject);
begin
   close;
end;


