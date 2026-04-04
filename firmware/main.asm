.include "m16def.inc"

.def Temp1 = r16
.def Temp2 = r17
.def Temp3 = r18
.def Temp_Interrupt = r19
.def LCD_Data_Buffer = r20
.def LCD_Command_Buffer = r21
.def LCD_Counter = r22
.def DigitalData1 = r23
.def Received_Data = r24
.def Sent_Data = r25
.def Counter_01 = r26
.def Counter_02 = r27
.def Counter_03 = r28
.def Disp = r29
.def Dec1 = r2
.def Dec2 = r3
.def Memory_Buffer = r4
.def Data_Completement_Flag = r5
.def Data_Analysis_Flag = r6
.def Message_Analysis_Buffer = r7
.def Send_Message_Flag = r8
.def Not_Allow_Communication = r9
.def Seconds = r10
.def Minutes = r11
.def Memory_Location_00000100 = r12
.def Memory_Location_00001000 = r13
.def Memory_Location_00010000 = r14
.def Memory_Location_00100000 = r15

.equ Baud = 300
.equ Timer1_First_Value = 0xA473

.cseg
.org 0x0000
RJMP RESET
.org 0x0010
RJMP Timer1_OVF


RESET:
ldi LCD_Data_Buffer,0
ldi LCD_Command_Buffer,0
ldi LCD_Counter,0
ldi DigitalData1,0
ldi Temp1,low(RAMEND)
out SPL,Temp1
ldi Temp1, HIGH(RAMEND)
out SPH,Temp1
ldi Temp1,0b01111110
out DDRA,Temp1
ldi Temp1,0b00001110
out DDRB,Temp1
ldi Temp1,0b11111111
out DDRC,Temp1
ldi Temp1,0b11111110
out DDRD,Temp1
ldi Temp1,0b11111100
out PORTA,Temp1
ldi Temp1,0
out PORTB,Temp1
out PORTC,Temp1
OUT PORTD,Temp1
LDI Disp, $60
LDI Temp1,0
MOV Send_Message_Flag, Temp1
MOV Seconds, Temp1
MOV Minutes, Temp1
MOV Counter_01, Temp1
MOV Counter_02, Temp1
MOV Counter_03, Temp1
MOV Data_Analysis_Flag, Temp1
MOV Not_Allow_Communication, Temp1
STS 0x031D, Temp1
STS 0x031E, Temp1
STS 0x031F, Temp1
STS 0x0310, Temp1
STS 0x0313, Temp1
STS 0x0316, Temp1
STS 0x0319, Temp1
STS 0x0323, Temp1
STS 0x0326, Temp1
STS 0x0329, Temp1
STS 0x032C, Temp1
STS 0x0330, Temp1
STS 0x0333, Temp1
ldi Temp1, 0b00000100
out TIMSK, Temp1
ldi Temp1, high(Timer1_First_Value)
out TCNT1H, Temp1
ldi Temp1, low(Timer1_First_Value)
out TCNT1L, Temp1
ldi Temp1, 0b00000100
out TCCR1B, Temp1
CALL Init_ADC
CALL Init_UART
CALL Reset_LCD
CALL Init_LCD

SEI


LDI Temp1, 0b00000001
STS 0x031F, Temp1
CALL Restart_Modem

Main:
		CALL Wait_For_Startup
		CALL UART_Receiving
		CALL Check_For_Complete_Receiving
		CALL Analyse_Commands_00000001
		CALL Analyse_Commands_00000010
		CALL Analyse_Commands_00000100
		CALL Analyse_Commands_00001000
		CALL Analyse_Commands_00010000
		CALL Analyse_Commands_00100000
		CALL Store_Received_Message_Index
		CALL Show_Message
		CALL Wait_For_Showing_Message
		CALL Read_Message_Domain
		CALL Analyse_Message
		CALL Read_ON_OFF
		CALL Time_For_Read_Temperatures
		CALL Compare_ON_OFF
		CALL Compare_Temperatures
		CALL Compare_Switches
		CALL Send_Message_Data
		CALL Send_Message_Ranges
		CALL Send_Warning_Message
		CALL Wait_To_Send
		CALL Warning_Message_Management
		LDS Temp1, 0x0323
		LDI Temp2, 0b00110000
		OR Temp1, Temp2
		MOV LCD_Data_Buffer, Temp1
		CALL LCD_Data
		LDS Temp1, 0x0326
		LDI Temp2, 0b00110000
		OR Temp1, Temp2
		MOV LCD_Data_Buffer, Temp1
		CALL LCD_Data
		CALL Delete_Message
		CALL Delete_Memory
		CALL Check_UART_Allow_Sending
		CALL Check_Modem
		CALL Wait_For_AT_Answer
		CALL Restart_Modem
        RJMP Main


Timer1_OVF:
			  IN Temp_Interrupt, SREG
              PUSH Temp_Interrupt
              LDI Temp_Interrupt, high(Timer1_First_Value)
              OUT TCNT1H, Temp_Interrupt
              LDI Temp_Interrupt, low(Timer1_First_Value)
              OUT TCNT1L, Temp_Interrupt
			  INC Seconds
			  LDI Temp_Interrupt, 0b00111100
			  CP Seconds, Temp_Interrupt
			  BRNE Timer1_OVF_01
			  INC Minutes
			  LDI Temp_Interrupt, 0
			  MOV Seconds, Temp_Interrupt
			  LDI Temp_Interrupt, 0b00111100
			  CP Minutes, Temp_Interrupt
			  BRNE Timer1_OVF_01
			  LDI Temp_Interrupt, 0
			  MOV Minutes, Temp_Interrupt
Timer1_OVF_01:POP Temp_Interrupt
              OUT SREG, Temp_Interrupt
              RETI


Init_UART:
         LDI Temp1, high(6000000/(16*Baud)-1)
		 OUT UBRRH, Temp1
		 LDI Temp1, Low(6000000/(16*Baud)-1)
		 OUT UBRRL, Temp1
		 LDI Temp1, $18
		 OUT UCSRB, Temp1
		 RET


UART_Receiving:
                  CBI PORTA,6
UART_Receiving_00:LDI Counter_01, 0
				  LDI Counter_02, 0
UART_Receiving_01:SBIS UCSRA, RXC
			      RJMP UART_Receiving_02
				  IN Received_Data, UDR
				  MOV LCD_Data_Buffer, Received_Data
				  CALL LCD_Data
				  CALL Store_Commands
				  RJMP UART_Receiving_00
UART_Receiving_02:CPI Counter_01,255
                  BRNE UART_Receiving_04
				  CPI Counter_02,255
				  BRNE UART_Receiving_03
				  SBIS PORTA,6
				  RJMP UART_Receiving_05
				  RET
UART_Receiving_03:INC Counter_02
UART_Receiving_04:INC Counter_01
				  RJMP UART_Receiving_01
UART_Receiving_05:SBI PORTA,6
                  RJMP UART_Receiving_00


UART_Sending:   LDI Counter_01, 0
UART_Sending_01:SBIS PINA,7
			    RJMP UART_Sending_02
				CALL Delay_1s
			    INC Counter_01
				CPI Counter_01,15
				BRLT UART_Sending_01
				LDI Temp1, 0b00000001
				STS 0x0363, Temp1
				RET
UART_Sending_02:SBIS UCSRA, UDRE
			    RJMP UART_Sending_02
			    OUT UDR, Sent_Data
				MOV LCD_Data_Buffer, Sent_Data
				CALL LCD_Data
			    RET


Check_UART_Allow_Sending:
                            LDS Temp1, 0x0363
							SBRS Temp1, 0
							RET
							LDI Temp1, 0b00000001
                            STS 0x031F, Temp1
							CALL Restart_Modem
							LDI Temp1, 0b00000000
							STS 0x0363, Temp1
							RET


Store_Commands:
			      INC Disp
                  CLR r31
			      MOV r30, Disp
			      ST Z, Received_Data
			      CPI Disp, $FF
			      BREQ Store_Commands_01
			      RET
Store_Commands_01:LDI Disp, $D0
				  RET


Check_For_Complete_Receiving:
                                  LDI r30, $61
			                      BRNE Check_For_Complete_Receiving_01
								  LDI Temp3, 0b10000000
								  MOV Data_Completement_Flag, Temp3
				                  RET
Check_For_Complete_Receiving_01:  MOV r30, Disp
			                      LD Temp1, Z
					              LDI Temp3, 0b00001010
			                      CP Temp1, Temp3
			                      BREQ Check_For_Complete_Receiving_01_1
					              RJMP Check_For_Complete_Receiving_01_2
Check_For_Complete_Receiving_01_1:DEC r30
			                      LD Temp1, Z
					              LDI Temp3, 0b00001101
			                      CP Temp1, Temp3
			                      BREQ Check_For_Complete_Receiving_02_1
					              LDI Temp3, 0b10000010
								  MOV Data_Completement_Flag, Temp3
								  RET
Check_For_Complete_Receiving_02_1:LDI Temp3, 0b10000001
								  MOV Data_Completement_Flag, Temp3
                                  RET
Check_For_Complete_Receiving_01_2:LD Temp1, Z
					              LDI Temp3, 0b00001101
			                      CP Temp1, Temp3
			                      BREQ Check_For_Complete_Receiving_02_2
					              LDI Temp3, 0b10000010
								  MOV Data_Completement_Flag, Temp3
								  RET
Check_For_Complete_Receiving_02_2:DEC r30
			                      LD Temp1, Z
					              LDI Temp3, 'R'
			                      CP Temp1, Temp3
			                      BREQ Check_For_Complete_Receiving_03_2
					              LDI Temp3, 0b10000010
								  MOV Data_Completement_Flag, Temp3
								  RET
Check_For_Complete_Receiving_03_2:DEC r30
			                      LD Temp1, Z
					              LDI Temp3, 'O'
			                      CP Temp1, Temp3
			                      BREQ Check_For_Complete_Receiving_04_2
					              LDI Temp3, 0b10000010
								  MOV Data_Completement_Flag, Temp3
								  RET
Check_For_Complete_Receiving_04_2:DEC r30
			                      LD Temp1, Z
					              LDI Temp3, 'R'
			                      CP Temp1, Temp3
			                      BREQ Check_For_Complete_Receiving_05_2
					              LDI Temp3, 0b10000010
								  MOV Data_Completement_Flag, Temp3
								  RET
Check_For_Complete_Receiving_05_2:DEC r30
			                      LD Temp1, Z
					              LDI Temp3, 'R'
			                      CP Temp1, Temp3
			                      BREQ Check_For_Complete_Receiving_06_2
					              LDI Temp3, 0b10000010
								  MOV Data_Completement_Flag, Temp3
								  RET
Check_For_Complete_Receiving_06_2:DEC r30
			                      LD Temp1, Z
					              LDI Temp3, 'E'
			                      CP Temp1, Temp3
			                      BREQ Check_For_Complete_Receiving_06_2_1
					              LDI Temp3, 0b10000010
								  MOV Data_Completement_Flag, Temp3
								  RET
Check_For_Complete_Receiving_06_2_1:LDI Temp3, 0b10000001
								    MOV Data_Completement_Flag, Temp3
                                    RET


Analyse_Commands_00000001:

Analyse_Commands_10:LDI r30, $60
Analyse_Commands_11:CP r30, Disp
                    BRNE Analyse_Commands_12
					LDI Temp1, 0b11111110
					AND Data_Analysis_Flag, Temp1
					RET
Analyse_Commands_12:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'E'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_11
Analyse_Commands_13:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'R'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_11
Analyse_Commands_14:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'R'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_11
Analyse_Commands_15:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'O'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_11
Analyse_Commands_16:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'R'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_11
Analyse_Commands_17:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 0b00001101
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_11
Analyse_Commands_18:LDI Temp1, 0b00000001
					OR Data_Analysis_Flag, Temp1
					RET


Analyse_Commands_00000010:

Analyse_Commands_20:LDI r30, $60
Analyse_Commands_21:CP r30, Disp
                    BRNE Analyse_Commands_22
					LDI Temp1, 0b11111101
					AND Data_Analysis_Flag, Temp1
					RET
Analyse_Commands_22:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'O'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_21
Analyse_Commands_23:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'K'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_21
Analyse_Commands_24:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 0b00001101
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_21
Analyse_Commands_25:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 0b00001010
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_21
Analyse_Commands_26:LDI Temp1, 0b00000010
					OR Data_Analysis_Flag, Temp1
					RET


Analyse_Commands_00000100:

Analyse_Commands_30:LDI r30, $60
Analyse_Commands_31:CP r30, Disp
                    BRNE Analyse_Commands_32
					LDI Temp1, 0b11111011
					AND Data_Analysis_Flag, Temp1
					RET
Analyse_Commands_32:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, '+'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_31
Analyse_Commands_33:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'C'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_31
Analyse_Commands_34:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'M'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_31
Analyse_Commands_35:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'T'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_31
Analyse_Commands_36:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'I'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_31
Analyse_Commands_37:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, ':'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_31
Analyse_Commands_38:LDI Temp1, 0b00000100
					OR Data_Analysis_Flag, Temp1
					MOV Memory_Location_00000100, r30
					RET


Analyse_Commands_00001000:

Analyse_Commands_40:LDI r30, $60
Analyse_Commands_41:CP r30, Disp
                    BRNE Analyse_Commands_42
					LDI Temp1, 0b11110111
					AND Data_Analysis_Flag, Temp1
					RET
Analyse_Commands_42:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, '+'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_41
Analyse_Commands_43:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'C'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_41
Analyse_Commands_44:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'M'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_41
Analyse_Commands_45:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'G'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_41
Analyse_Commands_46:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'R'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_41
Analyse_Commands_47:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, ':'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_41
Analyse_Commands_48:LDI Temp1, 0b00001000
					OR Data_Analysis_Flag, Temp1
					MOV Memory_Location_00001000, r30
					RET


Analyse_Commands_00010000:

Analyse_Commands_50:LDI r30, $60
Analyse_Commands_51:CP r30, Disp
                    BRNE Analyse_Commands_52
					LDI Temp1, 0b11101111
					AND Data_Analysis_Flag, Temp1
					RET
Analyse_Commands_52:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, '+'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_51
Analyse_Commands_53:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'C'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_51
Analyse_Commands_54:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'M'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_51
Analyse_Commands_55:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'G'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_51
Analyse_Commands_56:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'S'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_51
Analyse_Commands_57:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, ':'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_51
Analyse_Commands_58:LDI Temp1, 0b00010000
					OR Data_Analysis_Flag, Temp1
					MOV Memory_Location_00010000, r30
					RET


Analyse_Commands_00100000:

Analyse_Commands_60:LDI r30, $60
Analyse_Commands_61:CP r30, Disp
                    BRNE Analyse_Commands_62
					LDI Temp1, 0b11011111
					AND Data_Analysis_Flag, Temp1
					RET
Analyse_Commands_62:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, '+'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_61
Analyse_Commands_63:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'C'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_61
Analyse_Commands_64:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'D'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_61
Analyse_Commands_65:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, 'S'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_61
Analyse_Commands_66:INC r30
					LD Memory_Buffer, Z
					LDI Temp3, ':'
					CP Memory_Buffer, Temp3
					BRNE Analyse_Commands_61
Analyse_Commands_67:LDI Temp1, 0b00100000
					OR Data_Analysis_Flag, Temp1
					MOV Memory_Location_00100000, r30
					RET


Store_Received_Message_Index:
                                SBRS Data_Analysis_Flag, 2
			                    RET
			                    MOV r30, Memory_Location_00000100
Store_Received_Message_Index_01:CP r30, Disp
                                BRNE Store_Received_Message_Index_02
								LDI Temp1, 0b11111011
			                    AND Data_Analysis_Flag, Temp1
			                    RET
Store_Received_Message_Index_02:INC r30
			                    LD Memory_Buffer, Z
			                    LDI Temp3, ','
			                    CP Memory_Buffer, Temp3
			                    BRNE Store_Received_Message_Index_01
Store_Received_Message_Index_03:INC r30
			                    LD Memory_Buffer, Z
			                    STS 0x035E, Memory_Buffer
			                    RET


Show_Message:
                SBRS Data_Analysis_Flag, 2
				RET
			    SBRC Not_Allow_Communication,0
			    RET
				CALL Show_Message_Command
				LDI Temp1, 0b00000001
				STS 0x0360, Temp1
				STS 0x0361, Minutes
				STS 0x0362, Seconds
				LDI Temp1, 0b00000001
			    OR Not_Allow_Communication, Temp1
			    RET


Show_Message_Command:
               LDI Sent_Data, 'A'
		       CALL UART_Sending
		       LDI Sent_Data, 'T'
		       CALL UART_Sending
		       LDI Sent_Data, '+'
		       CALL UART_Sending
		       LDI Sent_Data, 'C'
		       CALL UART_Sending
		       LDI Sent_Data, 'M'
		       CALL UART_Sending
		       LDI Sent_Data, 'G'
		       CALL UART_Sending
		       LDI Sent_Data, 'R'
		       CALL UART_Sending
		       LDI Sent_Data, '='
		       CALL UART_Sending
		       LDS Sent_Data, 0x035E
		       CALL UART_Sending
		       LDI Sent_Data, 0b00001101
		       CALL UART_Sending
		       RET

Wait_For_Showing_Message:
                            LDS Temp1, 0x0360
				            CPI Temp1, 0
				            BRNE Wait_For_Showing_Message_00
				            RET
Wait_For_Showing_Message_00:LDS Temp1, 0x0361
		                    CP Minutes, Temp1
		                    BREQ Wait_For_Showing_Message_04
			                CP Minutes, Temp1
			                BRGE Wait_For_Showing_Message_02
			                SUB Temp1, Minutes
			                LDI Temp2, 57
			                CP Temp2, Temp1
			                BRGE Wait_For_Showing_Message_05
			                LDI Temp2, 58
			                CP Temp2, Temp1
			                BRGE Wait_For_Showing_Message_01
			                RJMP Wait_For_Showing_Message_04
Wait_For_Showing_Message_01:LDS Temp1, 0x0362
		                    CP Seconds, Temp1
				            BRGE Wait_For_Showing_Message_05
							RJMP Wait_For_Showing_Message_04
Wait_For_Showing_Message_02:LDS Temp1, 0x0361
				            MOV Temp2, Minutes
				            SUB Temp2, Temp1
				            LDI Temp1, 3
				            CP Temp2, Temp1
				            BRGE Wait_For_Showing_Message_05
				            LDI Temp1, 2
				            CP Temp2, Temp1
				            BRGE Wait_For_Showing_Message_03
				            RJMP Wait_For_Showing_Message_04
Wait_For_Showing_Message_03:LDS Temp1, 0x0362
		                    CP Seconds, Temp1
				            BRGE Wait_For_Showing_Message_05
Wait_For_Showing_Message_04:SBRS Data_Analysis_Flag, 3
                            RET
				            LDI Temp1, 0b11111011
			                AND Data_Analysis_Flag, Temp1
Wait_For_Showing_Message_05:LDI Temp1, 0b11111110
                            AND Not_Allow_Communication, Temp1
				            RET


Read_Message_Domain:
                       SBRS Data_Analysis_Flag, 3
					   RET
					   MOV r30, Memory_Location_00001000
Read_Message_Domain_01:CP r30, Disp
                       BRNE Read_Message_Domain_02
					   LDI Temp1, 0b11110111
			           AND Data_Analysis_Flag, Temp1
					   LDI Temp1, 0
					   STS 0x0336, Temp1
					   STS 0x033A, Temp1
				       RET
Read_Message_Domain_02:INC r30
				       LD Memory_Buffer, Z
				       LDI Temp3, 0b00001101
				       CP Memory_Buffer, Temp3
				       BRNE Read_Message_Domain_01
Read_Message_Domain_03:INC r30
			           LD Memory_Buffer, Z
				       LDI Temp3, 0b00001010
				       CP Memory_Buffer, Temp3
				       BRNE Read_Message_Domain_01
Read_Message_Domain_04:INC r30
                       STS 0x0336, r30
Read_Message_Domain_05:CP r30, Disp
                       BRNE Read_Message_Domain_06
					   STS 0x033A, r30
				       RET
Read_Message_Domain_06:LD Temp1, Z
                       LDI Temp3, 0b00001010
				       CP Temp1, Temp3
				       BREQ Read_Message_Domain_07
					   INC r30
					   RJMP Read_Message_Domain_05
Read_Message_Domain_07:STS 0x033A, r30
				       RET


Analyse_Message:
                   SBRS Data_Analysis_Flag, 3
				   RET
				   LDS r30, 0x0336
Analyse_Message_01:LDS Temp1, 0x033A
                   CP Temp1, r30
				   BREQ Analyse_Message_09
Analyse_Message_02:LD Memory_Buffer, Z
				   LDI Temp3, 'T'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_03
				   INC r30
				   RJMP Analyse_Message_01
Analyse_Message_03:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, '_'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_04
				   RJMP Analyse_Message_01
Analyse_Message_04:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'O'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_05
				   RJMP Analyse_Message_01
Analyse_Message_05:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'N'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_06
				   RJMP Analyse_Message_01
Analyse_Message_06:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111000
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_07
				   RJMP Analyse_Message_01
Analyse_Message_07:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_08
				   RJMP Analyse_Message_01
Analyse_Message_08:MOV Message_Analysis_Buffer, Memory_Buffer
				   CALL Perform_Switches_ON
				   LDI Temp1, 0b00000001
			       OR Send_Message_Flag, Temp1
				   INC r30
				   RJMP Analyse_Message_01

Analyse_Message_09:LDS r30, 0x0336
Analyse_Message_10:LDS Temp1, 0x033A
                   CP Temp1, r30
				   BREQ Analyse_Message_19
Analyse_Message_11:LD Memory_Buffer, Z
				   LDI Temp3, 'T'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_12
				   INC r30
				   RJMP Analyse_Message_10
Analyse_Message_12:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, '_'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_13
				   RJMP Analyse_Message_10
Analyse_Message_13:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'O'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_14
				   RJMP Analyse_Message_10
Analyse_Message_14:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'F'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_15
				   RJMP Analyse_Message_10
Analyse_Message_15:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'F'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_16
				   RJMP Analyse_Message_10
Analyse_Message_16:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111000
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_17
				   RJMP Analyse_Message_10
Analyse_Message_17:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_18
				   RJMP Analyse_Message_10
Analyse_Message_18:MOV Message_Analysis_Buffer, Memory_Buffer
				   CALL Perform_Switches_OFF
				   LDI Temp1, 0b00000001
			       OR Send_Message_Flag, Temp1
				   INC r30
				   RJMP Analyse_Message_10

Analyse_Message_19:LDS r30, 0x0336
Analyse_Message_20:LDS Temp1, 0x033A
                   CP Temp1, r30
				   BREQ Analyse_Message_29
Analyse_Message_21:LD Memory_Buffer, Z
				   LDI Temp3, 'S'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_22
				   INC r30
				   RJMP Analyse_Message_20
Analyse_Message_22:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'E'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_23
				   RJMP Analyse_Message_20
Analyse_Message_23:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'N'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_24
				   RJMP Analyse_Message_20
Analyse_Message_24:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'D'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_25
				   RJMP Analyse_Message_20
Analyse_Message_25:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'T'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_26
				   RJMP Analyse_Message_20
Analyse_Message_26:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'P'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_27
				   RJMP Analyse_Message_20
Analyse_Message_27:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'S'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_28
				   RJMP Analyse_Message_20
Analyse_Message_28:LDI Temp1, 0b00000001
			       OR Send_Message_Flag, Temp1
				   INC r30
				   RJMP Analyse_Message_20

Analyse_Message_29:LDS r30, 0x0336
Analyse_Message_30:LDS Temp1, 0x033A
                   CP Temp1, r30
				   BREQ Analyse_Message_37
Analyse_Message_31:LD Memory_Buffer, Z
				   LDI Temp3, 'S'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_32
				   INC r30
				   RJMP Analyse_Message_30
Analyse_Message_32:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'E'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_33
				   RJMP Analyse_Message_30
Analyse_Message_33:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'N'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_34
				   RJMP Analyse_Message_30
Analyse_Message_34:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'D'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_35
				   RJMP Analyse_Message_30
Analyse_Message_35:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'R'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_36
				   RJMP Analyse_Message_30
Analyse_Message_36:LDI Temp1, 0b00000010
			       OR Send_Message_Flag, Temp1
				   INC r30
				   RJMP Analyse_Message_30

Analyse_Message_37:LDS r30, 0x0336
Analyse_Message_38:LDS Temp1, 0x033A
                   CP Temp1, r30
				   BREQ Analyse_Message_47
Analyse_Message_39:LD Memory_Buffer, Z
				   LDI Temp3, 'T'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_40
				   INC r30
				   RJMP Analyse_Message_38
Analyse_Message_40:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'R'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_41
				   RJMP Analyse_Message_38
Analyse_Message_41:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, '_'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_42
				   RJMP Analyse_Message_38
Analyse_Message_42:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111000
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_43
				   RJMP Analyse_Message_38
Analyse_Message_43:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_44
				   RJMP Analyse_Message_38
Analyse_Message_44:STS 0x0344, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, ':'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_45
				   RJMP Analyse_Message_38
Analyse_Message_45:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_46
				   RJMP Analyse_Message_38
Analyse_Message_46:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_48
				   RJMP Analyse_Message_38
Analyse_Message_47:RJMP Analyse_Message_56
Analyse_Message_48:STS 0x0340, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_49
				   RJMP Analyse_Message_38
Analyse_Message_49:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_50
				   RJMP Analyse_Message_38
Analyse_Message_50:STS 0x0341, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, '-'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_51
				   RJMP Analyse_Message_38
Analyse_Message_51:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_52
				   RJMP Analyse_Message_38
Analyse_Message_52:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_53
				   RJMP Analyse_Message_38
Analyse_Message_53:STS 0x0342, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_54
				   RJMP Analyse_Message_38
Analyse_Message_54:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_55
				   RJMP Analyse_Message_38
Analyse_Message_55:STS 0x0343, Memory_Buffer
                   CALL Perform_Adj_Temperatures_Ranges
				   LDI Temp1, 0b00000010
			       OR Send_Message_Flag, Temp1
				   INC r30
				   RJMP Analyse_Message_38

Analyse_Message_56:LDS r30, 0x0336
Analyse_Message_57:LDS Temp1, 0x033A
                   CP Temp1, r30
				   BREQ Analyse_Message_67
Analyse_Message_58:LD Memory_Buffer, Z
				   LDI Temp3, 'P'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_59
				   INC r30
				   RJMP Analyse_Message_57
Analyse_Message_59:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'R'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_60
				   RJMP Analyse_Message_57
Analyse_Message_60:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, '_'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_61
				   RJMP Analyse_Message_57
Analyse_Message_61:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111000
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_62
				   RJMP Analyse_Message_57
Analyse_Message_62:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_63
				   RJMP Analyse_Message_57
Analyse_Message_63:STS 0x0345, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, ':'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_64
				   RJMP Analyse_Message_57
Analyse_Message_64:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00110010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_65
				   RJMP Analyse_Message_57
Analyse_Message_65:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_66
				   RJMP Analyse_Message_57
Analyse_Message_66:STS 0x0346, Memory_Buffer
                   CALL Perform_Adj_P_Ranges
				   LDI Temp1, 0b00000010
			       OR Send_Message_Flag, Temp1
				   INC r30
				   RJMP Analyse_Message_57

Analyse_Message_67:LDS r30, 0x0336
Analyse_Message_68:LDS Temp1, 0x033A
                   CP Temp1, r30
				   BREQ Analyse_Message_78
Analyse_Message_69:LD Memory_Buffer, Z
				   LDI Temp3, 'T'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_70
				   INC r30
				   RJMP Analyse_Message_68
Analyse_Message_70:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 'C'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_71
				   RJMP Analyse_Message_68
Analyse_Message_71:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, '_'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_72
				   RJMP Analyse_Message_68
Analyse_Message_72:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111000
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_73
				   RJMP Analyse_Message_68
Analyse_Message_73:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_74
				   RJMP Analyse_Message_68
Analyse_Message_74:STS 0x0347, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, ':'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_75
				   RJMP Analyse_Message_68
Analyse_Message_75:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_76
				   RJMP Analyse_Message_68
Analyse_Message_76:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_77
				   RJMP Analyse_Message_68
Analyse_Message_77:STS 0x0348, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_79
				   RJMP Analyse_Message_68
Analyse_Message_78:RJMP Analyse_Message_88
Analyse_Message_79:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_80
				   RJMP Analyse_Message_68
Analyse_Message_80:STS 0x0349, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_81
				   RJMP Analyse_Message_68
Analyse_Message_81:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_82
				   RJMP Analyse_Message_68
Analyse_Message_82:STS 0x034A, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, '_'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_83
				   RJMP Analyse_Message_68
Analyse_Message_83:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_84
				   RJMP Analyse_Message_68
Analyse_Message_84:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_85
				   RJMP Analyse_Message_68
Analyse_Message_85:STS 0x034B, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_86
				   RJMP Analyse_Message_68
Analyse_Message_86:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_87
				   RJMP Analyse_Message_68
Analyse_Message_87:STS 0x034C, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_89
				   RJMP Analyse_Message_68
Analyse_Message_88:RJMP Analyse_Message_98
Analyse_Message_89:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_90
				   RJMP Analyse_Message_68
Analyse_Message_90:STS 0x034D, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, '-'
				   CP Memory_Buffer, Temp3
				   BREQ Analyse_Message_91
				   RJMP Analyse_Message_68
Analyse_Message_91:INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_92
				   RJMP Analyse_Message_68
Analyse_Message_92:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_93
				   RJMP Analyse_Message_68
Analyse_Message_93:STS 0x034E, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_94
				   RJMP Analyse_Message_68
Analyse_Message_94:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_95
				   RJMP Analyse_Message_68
Analyse_Message_95:STS 0x034F, Memory_Buffer
                   INC r30
				   LD Memory_Buffer, Z
				   LDI Temp3, 0b00111010
				   CP Memory_Buffer, Temp3
				   BRLT Analyse_Message_96
				   RJMP Analyse_Message_68
Analyse_Message_96:LDI Temp3, 0b00110000
				   CP Memory_Buffer, Temp3
				   BRGE Analyse_Message_97
				   RJMP Analyse_Message_68
Analyse_Message_97:STS 0x0350, Memory_Buffer
                   CALL Perform_Adj_Calibration
				   LDI Temp1, 0b00000001
			       OR Send_Message_Flag, Temp1
				   INC r30
				   RJMP Analyse_Message_68

Analyse_Message_98:LDS r30, 0x0336
Analyse_Message_99:LDS Temp1, 0x033A
                   CP Temp1, r30
				   BREQ Analyse_Message_105
Analyse_Message_100:LD Memory_Buffer, Z
				    LDI Temp3, 'T'
				    CP Memory_Buffer, Temp3
				    BREQ Analyse_Message_101
				    INC r30
				    RJMP Analyse_Message_99
Analyse_Message_101:INC r30
	                LD Memory_Buffer, Z
				    LDI Temp3, 'W'
				    CP Memory_Buffer, Temp3
				    BREQ Analyse_Message_102
				    RJMP Analyse_Message_99
Analyse_Message_102:INC r30
				    LD Memory_Buffer, Z
				    LDI Temp3, 0b00111000
				    CP Memory_Buffer, Temp3
				    BRLT Analyse_Message_103
				    RJMP Analyse_Message_99
Analyse_Message_103:LDI Temp3, 0b00110000
				    CP Memory_Buffer, Temp3
				    BRGE Analyse_Message_104
				    RJMP Analyse_Message_99
Analyse_Message_104:STS 0x0351, Memory_Buffer
                    CALL Perform_Temperature_Warning_Reply
				    INC r30
				    RJMP Analyse_Message_99

Analyse_Message_105:LDS r30, 0x0336
Analyse_Message_106:LDS Temp1, 0x033A
                    CP Temp1, r30
				    BREQ Analyse_Message_112
Analyse_Message_107:LD Memory_Buffer, Z
				    LDI Temp3, 'P'
				    CP Memory_Buffer, Temp3
				    BREQ Analyse_Message_108
				    INC r30
				    RJMP Analyse_Message_106
Analyse_Message_108:INC r30
				    LD Memory_Buffer, Z
				    LDI Temp3, 'W'
				    CP Memory_Buffer, Temp3
				    BREQ Analyse_Message_109
				    RJMP Analyse_Message_106
Analyse_Message_109:INC r30
				    LD Memory_Buffer, Z
				    LDI Temp3, 0b00111000
				    CP Memory_Buffer, Temp3
				    BRLT Analyse_Message_110
				    RJMP Analyse_Message_106
Analyse_Message_110:LDI Temp3, 0b00110000
				    CP Memory_Buffer, Temp3
				    BRGE Analyse_Message_111
				    RJMP Analyse_Message_106
Analyse_Message_111:STS 0x0352, Memory_Buffer
                    CALL Perform_P_Warning_Reply
				    INC r30
				    RJMP Analyse_Message_106
Analyse_Message_112:LDI Temp1, 0b11110111
			        AND Data_Analysis_Flag, Temp1
					LDI Temp1, 0b00000001
					STS 0x0364, Temp1
                    LDI Temp1, 0
					STS 0x0336, Temp1
					STS 0x033A, Temp1
					RET


Perform_Switches_ON:
Perform_Switches_ON_01:LDI Temp3, 0b00110000
                       CP Message_Analysis_Buffer, Temp3
				       BRNE Perform_Switches_ON_02
				       LDS Temp1, 0x0280
					   LDI Temp2, 0b00000001
			           OR Temp1, Temp2
				       STS 0x0280, Temp1
				       RET
Perform_Switches_ON_02:LDI Temp3, 0b00110001
                       CP Message_Analysis_Buffer, Temp3
				       BRNE Perform_Switches_ON_03
				       LDS Temp1, 0x0280
					   LDI Temp2, 0b00000010
			           OR Temp1, Temp2
				       STS 0x0280, Temp1
				       RET
Perform_Switches_ON_03:LDI Temp3, 0b00110010
                       CP Message_Analysis_Buffer, Temp3
				       BRNE Perform_Switches_ON_04
				       LDS Temp1, 0x0280
				       LDI Temp2, 0b00000100
			           OR Temp1, Temp2
				       STS 0x0280, Temp1
				       RET
Perform_Switches_ON_04:LDI Temp3, 0b00110011
                       CP Message_Analysis_Buffer, Temp3
				       BRNE Perform_Switches_ON_05
				       LDS Temp1, 0x0280
			           LDI Temp2, 0b00001000
			           OR Temp1, Temp2
				       STS 0x0280, Temp1
				       RET
Perform_Switches_ON_05:LDI Temp3, 0b00110100
                       CP Message_Analysis_Buffer, Temp3
				       BRNE Perform_Switches_ON_06
				       LDS Temp1, 0x0280
				       LDI Temp2, 0b00010000
			           OR Temp1, Temp2
				       STS 0x0280, Temp1
			 	       RET
Perform_Switches_ON_06:LDI Temp3, 0b00110101
                       CP Message_Analysis_Buffer, Temp3
				       BRNE Perform_Switches_ON_07
				       LDS Temp1, 0x0280
				       LDI Temp2, 0b00100000
			           OR Temp1, Temp2
				       STS 0x0280, Temp1
				       RET
Perform_Switches_ON_07:LDI Temp3, 0b00110110
                       CP Message_Analysis_Buffer, Temp3
				       BRNE Perform_Switches_ON_08
				       LDS Temp1, 0x0280
				       LDI Temp2, 0b01000000
			           OR Temp1, Temp2
				       STS 0x0280, Temp1
				       RET
Perform_Switches_ON_08:LDI Temp3, 0b00110111
                       CP Message_Analysis_Buffer, Temp3
				       BRNE Perform_Switches_ON_09
				       LDS Temp1, 0x0280
				       LDI Temp2, 0b10000000
			           OR Temp1, Temp2
				       STS 0x0280, Temp1
Perform_Switches_ON_09:RET


Perform_Switches_OFF:
Perform_Switches_OFF_01:LDI Temp3, 0b00110000
                        CP Message_Analysis_Buffer, Temp3
				        BRNE Perform_Switches_OFF_02
				        LDS Temp1, 0x0280
				        LDI Temp2, 0b11111110
			            AND Temp1, Temp2
				        STS 0x0280, Temp1
				        RET
Perform_Switches_OFF_02:LDI Temp3, 0b00110001
                        CP Message_Analysis_Buffer, Temp3
				        BRNE Perform_Switches_OFF_03
				        LDS Temp1, 0x0280
				        LDI Temp2, 0b11111101
			            AND Temp1, Temp2
				        STS 0x0280, Temp1
				        RET
Perform_Switches_OFF_03:LDI Temp3, 0b00110010
                        CP Message_Analysis_Buffer, Temp3
				        BRNE Perform_Switches_OFF_04
				        LDS Temp1, 0x0280
				        LDI Temp2, 0b11111011
			            AND Temp1, Temp2
				        STS 0x0280, Temp1
				        RET
Perform_Switches_OFF_04:LDI Temp3, 0b00110011
                        CP Message_Analysis_Buffer, Temp3
			 	        BRNE Perform_Switches_OFF_05
				        LDS Temp1, 0x0280
				        LDI Temp2, 0b11110111
			            AND Temp1, Temp2
				        STS 0x0280, Temp1
				        RET
Perform_Switches_OFF_05:LDI Temp3, 0b00110100
                        CP Message_Analysis_Buffer, Temp3
				        BRNE Perform_Switches_OFF_06
				        LDS Temp1, 0x0280
				        LDI Temp2, 0b11101111
			            AND Temp1, Temp2
				        STS 0x0280, Temp1
				        RET
Perform_Switches_OFF_06:LDI Temp3, 0b00110101
                        CP Message_Analysis_Buffer, Temp3
				        BRNE Perform_Switches_OFF_07
				        LDS Temp1, 0x0280
				        LDI Temp2, 0b11011111
			            AND Temp1, Temp2
				        STS 0x0280, Temp1
				        RET
Perform_Switches_OFF_07:LDI Temp3, 0b00110110
                        CP Message_Analysis_Buffer, Temp3
				        BRNE Perform_Switches_OFF_08
				        LDS Temp1, 0x0280
				        LDI Temp2, 0b10111111
			            AND Temp1, Temp2
				        STS 0x0280, Temp1
				        RET
Perform_Switches_OFF_08:LDI Temp3, 0b00110111
                        CP Message_Analysis_Buffer, Temp3
				        BRNE Perform_Switches_OFF_09
				        LDS Temp1, 0x0280
				        LDI Temp2, 0b01111111
			            AND Temp1, Temp2
				        STS 0x0280, Temp1
Perform_Switches_OFF_09:RET


Perform_Adj_Temperatures_Ranges:
                                   LDS Temp1, 0x0344
								   LDI Temp2, 0b00001111
								   AND Temp1, Temp2
Perform_Adj_Temperatures_Ranges_01:CPI Temp1, 0
								   BRNE Perform_Adj_Temperatures_Ranges_02
								   LDS Temp2, 0x0340
								   STS 0x0230, Temp2
								   LDS Temp2, 0x0341
								   STS 0x0231, Temp2
								   LDS Temp2, 0x0342
								   STS 0x0232, Temp2
								   LDS Temp2, 0x0343
								   STS 0x0233, Temp2
								   RET
Perform_Adj_Temperatures_Ranges_02:CPI Temp1, 1
								   BRNE Perform_Adj_Temperatures_Ranges_03
								   LDS Temp2, 0x0340
								   STS 0x0234, Temp2
								   LDS Temp2, 0x0341
								   STS 0x0235, Temp2
								   LDS Temp2, 0x0342
								   STS 0x0236, Temp2
								   LDS Temp2, 0x0343
								   STS 0x0237, Temp2
								   RET
Perform_Adj_Temperatures_Ranges_03:CPI Temp1, 2
								   BRNE Perform_Adj_Temperatures_Ranges_04
								   LDS Temp2, 0x0340
								   STS 0x0238, Temp2
								   LDS Temp2, 0x0341
								   STS 0x0239, Temp2
								   LDS Temp2, 0x0342
								   STS 0x023A, Temp2
								   LDS Temp2, 0x0343
								   STS 0x023B, Temp2
								   RET
Perform_Adj_Temperatures_Ranges_04:CPI Temp1, 3
								   BRNE Perform_Adj_Temperatures_Ranges_05
								   LDS Temp2, 0x0340
								   STS 0x023C, Temp2
								   LDS Temp2, 0x0341
								   STS 0x023D, Temp2
								   LDS Temp2, 0x0342
								   STS 0x023E, Temp2
								   LDS Temp2, 0x0343
								   STS 0x023F, Temp2
								   RET
Perform_Adj_Temperatures_Ranges_05:CPI Temp1, 4
								   BRNE Perform_Adj_Temperatures_Ranges_06
								   LDS Temp2, 0x0340
								   STS 0x0240, Temp2
								   LDS Temp2, 0x0341
								   STS 0x0241, Temp2
								   LDS Temp2, 0x0342
								   STS 0x0242, Temp2
								   LDS Temp2, 0x0343
								   STS 0x0243, Temp2
								   RET
Perform_Adj_Temperatures_Ranges_06:CPI Temp1, 5
								   BRNE Perform_Adj_Temperatures_Ranges_07
								   LDS Temp2, 0x0340
								   STS 0x0244, Temp2
								   LDS Temp2, 0x0341
								   STS 0x0245, Temp2
								   LDS Temp2, 0x0342
								   STS 0x0246, Temp2
								   LDS Temp2, 0x0343
								   STS 0x0247, Temp2
								   RET
Perform_Adj_Temperatures_Ranges_07:CPI Temp1, 6
								   BRNE Perform_Adj_Temperatures_Ranges_08
								   LDS Temp2, 0x0340
								   STS 0x0248, Temp2
								   LDS Temp2, 0x0341
								   STS 0x0249, Temp2
								   LDS Temp2, 0x0342
								   STS 0x024A, Temp2
								   LDS Temp2, 0x0343
								   STS 0x024B, Temp2
								   RET
Perform_Adj_Temperatures_Ranges_08:CPI Temp1, 6
								   BRNE Perform_Adj_Temperatures_Ranges_09
								   LDS Temp2, 0x0340
								   STS 0x024C, Temp2
								   LDS Temp2, 0x0341
								   STS 0x024D, Temp2
								   LDS Temp2, 0x0342
								   STS 0x024E, Temp2
								   LDS Temp2, 0x0343
								   STS 0x024F, Temp2
Perform_Adj_Temperatures_Ranges_09:RET


Perform_Adj_P_Ranges:
                        LDS Temp1, 0x0345
					    LDI Temp2, 0b00001111
					    AND Temp1, Temp2
Perform_Adj_P_Ranges_01:CPI Temp1, 0
                        BRNE Perform_Adj_P_Ranges_02
						LDI Temp3, 0b00000001
						RJMP Perform_Adj_P_Ranges_09
Perform_Adj_P_Ranges_02:CPI Temp1, 1
                        BRNE Perform_Adj_P_Ranges_03
						LDI Temp3, 0b00000010
						RJMP Perform_Adj_P_Ranges_09
Perform_Adj_P_Ranges_03:CPI Temp1, 2
                        BRNE Perform_Adj_P_Ranges_04
						LDI Temp3, 0b00000100
						RJMP Perform_Adj_P_Ranges_09
Perform_Adj_P_Ranges_04:CPI Temp1, 3
                        BRNE Perform_Adj_P_Ranges_05
						LDI Temp3, 0b00001000
						RJMP Perform_Adj_P_Ranges_09
Perform_Adj_P_Ranges_05:CPI Temp1, 4
                        BRNE Perform_Adj_P_Ranges_06
						LDI Temp3, 0b00010000
						RJMP Perform_Adj_P_Ranges_09
Perform_Adj_P_Ranges_06:CPI Temp1, 5
                        BRNE Perform_Adj_P_Ranges_07
						LDI Temp3, 0b00100000
						RJMP Perform_Adj_P_Ranges_09
Perform_Adj_P_Ranges_07:CPI Temp1, 6
                        BRNE Perform_Adj_P_Ranges_08
						LDI Temp3, 0b01000000
						RJMP Perform_Adj_P_Ranges_09
Perform_Adj_P_Ranges_08:CPI Temp1, 7
                        BRNE Perform_Adj_P_Ranges_09
						LDI Temp3, 0b10000000
Perform_Adj_P_Ranges_09:LDS Temp1, 0x0346
					    LDI Temp2, 0b00110001
						CP Temp1, Temp2
						BRNE Perform_Adj_P_Ranges_10
						LDS Temp1, 0x0270
						OR Temp1, Temp3
						STS 0x0270, Temp1
						RET
Perform_Adj_P_Ranges_10:LDS Temp1, 0x0270
						COM Temp3
						AND Temp1, Temp3
						STS 0x0270, Temp1
						RET


Perform_Adj_Calibration:
                           LDS Temp1, 0x0348
						   STS 0x0356, Temp1
						   LDS Temp1, 0x0349
						   STS 0x0357, Temp1
						   LDS Temp1, 0x034A
						   STS 0x0358, Temp1
						   CALL Calibration_Calculation
						   LDS Temp1, 0x0359
						   STS 0x0353, Temp1
                           LDS Temp1, 0x034B
						   STS 0x0356, Temp1
						   LDS Temp1, 0x034C
						   STS 0x0357, Temp1
						   LDS Temp1, 0x034D
						   STS 0x0358, Temp1
						   CALL Calibration_Calculation
						   LDS Temp1, 0x0359
						   STS 0x0354, Temp1
						   LDS Temp1, 0x034E
						   STS 0x0356, Temp1
						   LDS Temp1, 0x034F
						   STS 0x0357, Temp1
						   LDS Temp1, 0x0350
						   STS 0x0358, Temp1
						   CALL Calibration_Calculation
						   LDS Temp1, 0x0359
						   STS 0x0355, Temp1
Perform_Adj_Calibration_01:LDS Temp1, 0x0347
                           LDI Temp2, 0b00001111
						   AND Temp1, Temp2
						   CPI Temp1, 0
						   BRNE Perform_Adj_Calibration_02
						   LDS Temp2, 0x0353
						   STS 0x0290, Temp2
						   LDS Temp2, 0x0354
						   STS 0x0291, Temp2
						   LDS Temp2, 0x0355
						   STS 0x0292, Temp2
						   RET
Perform_Adj_Calibration_02:CPI Temp1, 1
						   BRNE Perform_Adj_Calibration_03
						   LDS Temp2, 0x0353
						   STS 0x0293, Temp2
						   LDS Temp2, 0x0354
						   STS 0x0294, Temp2
						   LDS Temp2, 0x0355
						   STS 0x0295, Temp2
						   RET
Perform_Adj_Calibration_03:CPI Temp1, 2
						   BRNE Perform_Adj_Calibration_04
						   LDS Temp2, 0x0353
						   STS 0x0296, Temp2
						   LDS Temp2, 0x0354
						   STS 0x0297, Temp2
						   LDS Temp2, 0x0355
						   STS 0x0298, Temp2
						   RET
Perform_Adj_Calibration_04:CPI Temp1, 3
						   BRNE Perform_Adj_Calibration_05
						   LDS Temp2, 0x0353
						   STS 0x0299, Temp2
						   LDS Temp2, 0x0354
						   STS 0x029A, Temp2
						   LDS Temp2, 0x0355
						   STS 0x029B, Temp2
						   RET
Perform_Adj_Calibration_05:CPI Temp1, 4
						   BRNE Perform_Adj_Calibration_06
						   LDS Temp2, 0x0353
						   STS 0x029C, Temp2
						   LDS Temp2, 0x0354
						   STS 0x029D, Temp2
						   LDS Temp2, 0x0355
						   STS 0x029E, Temp2
						   RET
Perform_Adj_Calibration_06:CPI Temp1, 5
						   BRNE Perform_Adj_Calibration_07
						   LDS Temp2, 0x0353
						   STS 0x029F, Temp2
						   LDS Temp2, 0x0354
						   STS 0x02A0, Temp2
						   LDS Temp2, 0x0355
						   STS 0x02A1, Temp2
						   RET
Perform_Adj_Calibration_07:CPI Temp1, 6
						   BRNE Perform_Adj_Calibration_08
						   LDS Temp2, 0x0353
						   STS 0x02A2, Temp2
						   LDS Temp2, 0x0354
						   STS 0x02A3, Temp2
						   LDS Temp2, 0x0355
						   STS 0x02A4, Temp2
						   RET
Perform_Adj_Calibration_08:CPI Temp1, 7
						   BRNE Perform_Adj_Calibration_09
						   LDS Temp2, 0x0353
						   STS 0x02A5, Temp2
						   LDS Temp2, 0x0354
						   STS 0x02A6, Temp2
						   LDS Temp2, 0x0355
						   STS 0x02A7, Temp2
Perform_Adj_Calibration_09:RET




Calibration_Calculation:
                           LDS Temp1, 0x0356
						   LDI Temp2, 0b00001111
						   AND Temp1, Temp2
						   LDI Temp2, 100
						   MUL Temp1, Temp2
						   MOV Temp3, r0
						   LDS Temp1, 0x0357
						   LDI Temp2, 0b00001111
						   AND Temp1, Temp2
						   LDI Temp2, 10
						   MUL Temp1, Temp2
						   MOV Temp2, r0
						   ADD Temp3, Temp2
						   LDS Temp1, 0x0358
						   LDI Temp2, 0b00001111
						   AND Temp1, Temp2
						   ADD Temp3, Temp1
						   STS 0x0359, Temp3
						   RET


Perform_Temperature_Warning_Reply:
                                     LDS Temp1, 0x0351
					                 LDI Temp2, 0b00001111
					                 AND Temp1, Temp2
Perform_Temperature_Warning_Reply_01:CPI Temp1, 0
                                     BRNE Perform_Temperature_Warning_Reply_02
						             LDI Temp3, 0b00000001
						             RJMP Perform_Temperature_Warning_Reply_09
Perform_Temperature_Warning_Reply_02:CPI Temp1, 1
                                     BRNE Perform_Temperature_Warning_Reply_03
						             LDI Temp3, 0b00000010
						             RJMP Perform_Temperature_Warning_Reply_09
Perform_Temperature_Warning_Reply_03:CPI Temp1, 2
                                     BRNE Perform_Temperature_Warning_Reply_04
						             LDI Temp3, 0b00000100
						             RJMP Perform_Temperature_Warning_Reply_09
Perform_Temperature_Warning_Reply_04:CPI Temp1, 3
                                     BRNE Perform_Temperature_Warning_Reply_05
						             LDI Temp3, 0b00001000
						             RJMP Perform_Temperature_Warning_Reply_09
Perform_Temperature_Warning_Reply_05:CPI Temp1, 4
                                     BRNE Perform_Temperature_Warning_Reply_06
						             LDI Temp3, 0b00010000
						             RJMP Perform_Temperature_Warning_Reply_09
Perform_Temperature_Warning_Reply_06:CPI Temp1, 5
                                     BRNE Perform_Temperature_Warning_Reply_07
						             LDI Temp3, 0b00100000
						             RJMP Perform_Temperature_Warning_Reply_09
Perform_Temperature_Warning_Reply_07:CPI Temp1, 6
                                     BRNE Perform_Temperature_Warning_Reply_08
						             LDI Temp3, 0b01000000
						             RJMP Perform_Temperature_Warning_Reply_09
Perform_Temperature_Warning_Reply_08:CPI Temp1, 7
                                     BRNE Perform_Temperature_Warning_Reply_09
						             LDI Temp3, 0b10000000
Perform_Temperature_Warning_Reply_09:LDS Temp1, 0x0316
						             OR Temp1, Temp3
						             STS 0x0316, Temp1
						             RET


Perform_P_Warning_Reply:
                           LDS Temp1, 0x0352
					       LDI Temp2, 0b00001111
					       AND Temp1, Temp2
Perform_P_Warning_Reply_01:CPI Temp1, 0
                           BRNE Perform_P_Warning_Reply_02
						   LDI Temp3, 0b00000001
						   RJMP Perform_P_Warning_Reply_09
Perform_P_Warning_Reply_02:CPI Temp1, 1
                           BRNE Perform_P_Warning_Reply_03
						   LDI Temp3, 0b00000010
						   RJMP Perform_P_Warning_Reply_09
Perform_P_Warning_Reply_03:CPI Temp1, 2
                           BRNE Perform_P_Warning_Reply_04
						   LDI Temp3, 0b00000100
						   RJMP Perform_P_Warning_Reply_09
Perform_P_Warning_Reply_04:CPI Temp1, 3
                           BRNE Perform_P_Warning_Reply_05
						   LDI Temp3, 0b00001000
						   RJMP Perform_P_Warning_Reply_09
Perform_P_Warning_Reply_05:CPI Temp1, 4
                           BRNE Perform_P_Warning_Reply_06
						   LDI Temp3, 0b00010000
						   RJMP Perform_P_Warning_Reply_09
Perform_P_Warning_Reply_06:CPI Temp1, 5
                           BRNE Perform_P_Warning_Reply_07
						   LDI Temp3, 0b00100000
						   RJMP Perform_P_Warning_Reply_09
Perform_P_Warning_Reply_07:CPI Temp1, 6
                           BRNE Perform_P_Warning_Reply_08
						   LDI Temp3, 0b01000000
						   RJMP Perform_P_Warning_Reply_09
Perform_P_Warning_Reply_08:CPI Temp1, 7
                           BRNE Perform_P_Warning_Reply_09
						   LDI Temp3, 0b10000000
Perform_P_Warning_Reply_09:LDS Temp1, 0x0319
						   OR Temp1, Temp3
						   STS 0x0319, Temp1
						   RET


Send_Message_Data:
                     SBRS Send_Message_Flag, 0
				     RET
				     SBRC Not_Allow_Communication,0
				     RET
					 MOV Temp1, Data_Completement_Flag
				     CPI Temp1, 0b10000000
				     BREQ Send_Message_Data_01
				     LDI Temp1, 0
				     MOV Counter_03, Temp1
				     RET
Send_Message_Data_01:INC Counter_03
                     CPI Counter_03, 0b00100000
					 BREQ Send_Message_Data_02
					 RET
Send_Message_Data_02:LDI Temp1, 0
				     MOV Counter_03, Temp1
                     CALL Send_Message
                     LDI Sent_Data, 'T'
		             CALL UART_Sending
					 LDI Sent_Data, '1'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
			         LDS Sent_Data, 0x0200
					 CALL UART_Sending
					 LDS Sent_Data, 0x0201
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'T'
		             CALL UART_Sending
					 LDI Sent_Data, '2'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Sent_Data, 0x0202
					 CALL UART_Sending
					 LDS Sent_Data, 0x0203
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'T'
		             CALL UART_Sending
					 LDI Sent_Data, '3'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Sent_Data, 0x0204
					 CALL UART_Sending
					 LDS Sent_Data, 0x0205
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'T'
		             CALL UART_Sending
					 LDI Sent_Data, '4'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Sent_Data, 0x0206
					 CALL UART_Sending
					 LDS Sent_Data, 0x0207
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'T'
		             CALL UART_Sending
					 LDI Sent_Data, '5'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Sent_Data, 0x0208
					 CALL UART_Sending
					 LDS Sent_Data, 0x0209
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'T'
		             CALL UART_Sending
					 LDI Sent_Data, '6'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Sent_Data, 0x020A
					 CALL UART_Sending
					 LDS Sent_Data, 0x020B
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'T'
		             CALL UART_Sending
					 LDI Sent_Data, '7'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Sent_Data, 0x020C
					 CALL UART_Sending
					 LDS Sent_Data, 0x020D
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'T'
		             CALL UART_Sending
					 LDI Sent_Data, '8'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Sent_Data, 0x020E
					 CALL UART_Sending
					 LDS Sent_Data, 0x020F
					 CALL UART_Sending
					 LDI Sent_Data, 0b00001101
		             CALL UART_Sending

					 LDI Sent_Data, 'P'
		             CALL UART_Sending
					 LDI Sent_Data, '1'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Temp1, 0x0220
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 0
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'P'
		             CALL UART_Sending
					 LDI Sent_Data, '2'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Temp1, 0x0220
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 1
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'P'
		             CALL UART_Sending
					 LDI Sent_Data, '3'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Temp1, 0x0220
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 2
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'P'
		             CALL UART_Sending
					 LDI Sent_Data, '4'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Temp1, 0x0220
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 3
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'P'
		             CALL UART_Sending
					 LDI Sent_Data, '5'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Temp1, 0x0220
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 4
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'P'
		             CALL UART_Sending
					 LDI Sent_Data, '6'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Temp1, 0x0220
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 5
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'P'
		             CALL UART_Sending
					 LDI Sent_Data, '7'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Temp1, 0x0220
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 6
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'P'
		             CALL UART_Sending
					 LDI Sent_Data, '8'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 LDS Temp1, 0x0220
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 7
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, 0b00001101
		             CALL UART_Sending

					 LDI Sent_Data, 'S'
		             CALL UART_Sending
					 LDI Sent_Data, '1'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 IN Temp1, PORTC
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 0
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'S'
		             CALL UART_Sending
					 LDI Sent_Data, '2'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 IN Temp1, PORTC
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 1
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'S'
		             CALL UART_Sending
					 LDI Sent_Data, '3'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 IN Temp1, PORTC
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 2
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'S'
		             CALL UART_Sending
					 LDI Sent_Data, '4'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 IN Temp1, PORTC
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 3
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'S'
		             CALL UART_Sending
					 LDI Sent_Data, '5'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 IN Temp1, PORTC
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 4
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'S'
		             CALL UART_Sending
					 LDI Sent_Data, '6'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 IN Temp1, PORTC
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 5
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'S'
		             CALL UART_Sending
					 LDI Sent_Data, '7'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 IN Temp1, PORTC
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 6
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, ','
		             CALL UART_Sending
					 LDI Sent_Data, 'S'
		             CALL UART_Sending
					 LDI Sent_Data, '8'
		             CALL UART_Sending
					 LDI Sent_Data, ':'
		             CALL UART_Sending
					 IN Temp1, PORTC
					 LDI Sent_Data, 'F'
					 SBRC Temp1, 7
					 LDI Sent_Data, 'N'
					 CALL UART_Sending
					 LDI Sent_Data, 0b00011010
					 CALL UART_Sending
					 LDI Temp1, 0b00000001
			         OR Not_Allow_Communication, Temp1
					 LDS Temp1, 0x0302
					 LDI Temp2, 0b00000001
			         OR Temp1, Temp2
					 STS 0x0302, Temp1
					 STS 0x0303, Minutes
					 STS 0x0304, Seconds
					 STS 0x0300, Minutes
					 STS 0x0301, Seconds
					 RET


Send_Message_Ranges:
                       SBRS Send_Message_Flag, 1
				       RET
				       SBRC Not_Allow_Communication,0
				       RET
					   MOV Temp1, Data_Completement_Flag
				       CPI Temp1, 0b10000000
				       BREQ Send_Message_Ranges_01
				       LDI Temp1, 0
				       MOV Counter_03, Temp1
				       RET
Send_Message_Ranges_01:INC Counter_03
                       CPI Counter_03, 0b00100000
					   BREQ Send_Message_Ranges_02
					   RET
Send_Message_Ranges_02:LDI Temp1, 0
				       MOV Counter_03, Temp1
                       CALL Send_Message
                       LDI Sent_Data, 'T'
		               CALL UART_Sending
				  	   LDI Sent_Data, '1'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
			           LDS Sent_Data, 0x0230
					   CALL UART_Sending
					   LDS Sent_Data, 0x0231
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDS Sent_Data, 0x0232
					   CALL UART_Sending
					   LDS Sent_Data, 0x0233
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'T'
		               CALL UART_Sending
					   LDI Sent_Data, '2'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Sent_Data, 0x0234
					   CALL UART_Sending
					   LDS Sent_Data, 0x0235
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDS Sent_Data, 0x0236
					   CALL UART_Sending
					   LDS Sent_Data, 0x0237
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'T'
		               CALL UART_Sending
					   LDI Sent_Data, '3'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Sent_Data, 0x0238
					   CALL UART_Sending
					   LDS Sent_Data, 0x0239
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDS Sent_Data, 0x023A
					   CALL UART_Sending
					   LDS Sent_Data, 0x023B
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'T'
		               CALL UART_Sending
					   LDI Sent_Data, '4'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Sent_Data, 0x023C
					   CALL UART_Sending
					   LDS Sent_Data, 0x023D
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDS Sent_Data, 0x023E
					   CALL UART_Sending
					   LDS Sent_Data, 0x023F
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'T'
		               CALL UART_Sending
					   LDI Sent_Data, '5'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Sent_Data, 0x0240
					   CALL UART_Sending
					   LDS Sent_Data, 0x0241
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDS Sent_Data, 0x0242
					   CALL UART_Sending
					   LDS Sent_Data, 0x0243
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'T'
		               CALL UART_Sending
					   LDI Sent_Data, '6'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Sent_Data, 0x0244
					   CALL UART_Sending
					   LDS Sent_Data, 0x0245
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDS Sent_Data, 0x0246
					   CALL UART_Sending
					   LDS Sent_Data, 0x0247
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'T'
		               CALL UART_Sending
					   LDI Sent_Data, '7'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Sent_Data, 0x0248
					   CALL UART_Sending
					   LDS Sent_Data, 0x0249
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDS Sent_Data, 0x024A
					   CALL UART_Sending
					   LDS Sent_Data, 0x024B
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'T'
		               CALL UART_Sending
					   LDI Sent_Data, '8'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Sent_Data, 0x024C
					   CALL UART_Sending
					   LDS Sent_Data, 0x024D
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDS Sent_Data, 0x024E
					   CALL UART_Sending
					   LDS Sent_Data, 0x024F
					   CALL UART_Sending
					   LDI Sent_Data, 0b00001101
		               CALL UART_Sending

					   LDI Sent_Data, 'P'
		               CALL UART_Sending
					   LDI Sent_Data, '1'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0270
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 0
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'P'
		               CALL UART_Sending
					   LDI Sent_Data, '2'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0270
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 1
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'P'
		               CALL UART_Sending
					   LDI Sent_Data, '3'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0270
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 2
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'P'
		               CALL UART_Sending
					   LDI Sent_Data, '4'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0270
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 3
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'P'
		               CALL UART_Sending
					   LDI Sent_Data, '5'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0270
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 4
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'P'
		               CALL UART_Sending
					   LDI Sent_Data, '6'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0270
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 5
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'P'
		               CALL UART_Sending
					   LDI Sent_Data, '7'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0270
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 6
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'P'
		               CALL UART_Sending
					   LDI Sent_Data, '8'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0270
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 7
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, 0b00001101
		               CALL UART_Sending

					   LDI Sent_Data, 'S'
		               CALL UART_Sending
					   LDI Sent_Data, '1'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0280
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 0
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'S'
		               CALL UART_Sending
					   LDI Sent_Data, '2'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0280
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 1
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'S'
		               CALL UART_Sending
					   LDI Sent_Data, '3'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0280
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 2
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'S'
		               CALL UART_Sending
					   LDI Sent_Data, '4'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0280
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 3
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'S'
		               CALL UART_Sending
					   LDI Sent_Data, '5'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0280
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 4
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'S'
		               CALL UART_Sending
					   LDI Sent_Data, '6'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0280
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 5
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'S'
		               CALL UART_Sending
					   LDI Sent_Data, '7'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0280
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 6
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, ','
		               CALL UART_Sending
					   LDI Sent_Data, 'S'
		               CALL UART_Sending
					   LDI Sent_Data, '8'
		               CALL UART_Sending
					   LDI Sent_Data, ':'
		               CALL UART_Sending
					   LDS Temp1, 0x0280
					   LDI Sent_Data, 'F'
					   SBRC Temp1, 7
					   LDI Sent_Data, 'N'
					   CALL UART_Sending
					   LDI Sent_Data, 0b00011010
					   CALL UART_Sending
					   LDI Temp1, 0b00000001
			           OR Not_Allow_Communication, Temp1
					   LDS Temp1, 0x0302
					   LDI Temp2, 0b00000010
			           OR Temp1, Temp2
					   STS 0x0302, Temp1
					   STS 0x0305, Minutes
					   STS 0x0306, Seconds
					   STS 0x0300, Minutes
					   STS 0x0301, Seconds
					   RET


Send_Message:
         LDI Sent_Data, 'A'
		 CALL UART_Sending
		 LDI Sent_Data, 'T'
		 CALL UART_Sending
		 LDI Sent_Data, '+'
		 CALL UART_Sending
		 LDI Sent_Data, 'C'
		 CALL UART_Sending
		 LDI Sent_Data, 'M'
		 CALL UART_Sending
		 LDI Sent_Data, 'G'
		 CALL UART_Sending
		 LDI Sent_Data, 'S'
		 CALL UART_Sending
		 LDI Sent_Data, '='
		 CALL UART_Sending
		 LDI Sent_Data, '0'
		 CALL UART_Sending
		 LDI Sent_Data, '9'
		 CALL UART_Sending
		 LDI Sent_Data, '3'
		 CALL UART_Sending
		 LDI Sent_Data, '5'
		 CALL UART_Sending
		 LDI Sent_Data, '1'
		 CALL UART_Sending
		 LDI Sent_Data, '7'
		 CALL UART_Sending
		 LDI Sent_Data, '8'
		 CALL UART_Sending
		 LDI Sent_Data, '7'
		 CALL UART_Sending
		 LDI Sent_Data, '0'
		 CALL UART_Sending
		 LDI Sent_Data, '7'
		 CALL UART_Sending
		 LDI Sent_Data, '6'
		 CALL UART_Sending
		 LDI Sent_Data, 0b00001101
		 CALL UART_Sending
		 RET


Wait_To_Send:
                LDS Temp1, 0x0302
				CPI Temp1, 0
				BRNE Wait_To_Send_00
				RET
Wait_To_Send_00:LDS Temp1, 0x0300
		        CP Minutes, Temp1
		        BREQ Wait_To_Send_04
			    CP Minutes, Temp1
			    BRGE Wait_To_Send_02
			    SUB Temp1, Minutes
			    LDI Temp2, 57
			    CP Temp2, Temp1
			    BRGE Wait_To_Send_ME
			    LDI Temp2, 58
			    CP Temp2, Temp1
			    BRGE Wait_To_Send_01
			    RJMP Wait_To_Send_04
Wait_To_Send_01:LDS Temp1, 0x0301
		        CP Seconds, Temp1
				BRGE Wait_To_Send_09
				RJMP Wait_To_Send_04
Wait_To_Send_02:LDS Temp1, 0x0300
				MOV Temp2, Minutes
				SUB Temp2, Temp1
				LDI Temp1, 3
				CP Temp2, Temp1
				BRGE Wait_To_Send_09
				LDI Temp1, 2
				CP Temp2, Temp1
				BRGE Wait_To_Send_03
				RJMP Wait_To_Send_04
Wait_To_Send_ME:RJMP Wait_To_Send_09
Wait_To_Send_03:LDS Temp1, 0x0301
		        CP Seconds, Temp1
				BRGE Wait_To_Send_09
Wait_To_Send_04:SBRS Data_Analysis_Flag, 4
                RET
				LDI Temp1, 0b11101111
			    AND Data_Analysis_Flag, Temp1
				LDS Temp1, 0x0302
				SBRS Temp1, 0
				RJMP Wait_To_Send_05
				LDI Temp1, 0b11111110
			    AND Send_Message_Flag, Temp1
Wait_To_Send_05:LDS Temp1, 0x0302
                SBRS Temp1, 1
				RJMP Wait_To_Send_06
				LDI Temp1, 0b11111101
			    AND Send_Message_Flag, Temp1
Wait_To_Send_06:LDS Temp1, 0x0302
                SBRS Temp1, 0
				RJMP Wait_To_Send_07
				LDI Temp1, 0b00000001
				LDS Temp2, 0x0309
                OR Temp2, Temp1
				STS 0x0309, Temp2
Wait_To_Send_07:LDS Temp1, 0x0302
                SBRS Temp1, 1
				RJMP Wait_To_Send_08
				LDI Temp1, 0b00000010
				LDS Temp2, 0x0309
                OR Temp2, Temp1
				STS 0x0309, Temp2
Wait_To_Send_08:LDS Temp1, 0x0302
                SBRS Temp1, 2
				RJMP Wait_To_Send_09
				LDI Temp1, 0b00000100
				LDS Temp2, 0x0309
                OR Temp2, Temp1
                STS 0x0309, Temp2
Wait_To_Send_09:LDI Temp1, 0
                STS 0x0302, Temp1
				LDI Temp1, 0b11111110
                AND Not_Allow_Communication, Temp1
				RET


Delete_Memory:
                 CPI Disp,$60
				 BREQ Delete_Memory_01
				 LDI r30, $FF
		         LDI Temp3,0
Delete_Memory_00:CPI r30,$60
		         BREQ Delete_Memory_01
		         ST Z, Temp3
				 DEC r30
				 RJMP Delete_Memory_00
Delete_Memory_01:LDI Disp, $60
                 RET


Delete_Message:
         LDS Temp1, 0x0364
		 SBRS Temp1, 0
		 RET
		 LDI Sent_Data, 'A'
		 CALL UART_Sending
		 LDI Sent_Data, 'T'
		 CALL UART_Sending
		 LDI Sent_Data, '+'
		 CALL UART_Sending
		 LDI Sent_Data, 'C'
		 CALL UART_Sending
		 LDI Sent_Data, 'M'
		 CALL UART_Sending
		 LDI Sent_Data, 'G'
		 CALL UART_Sending
		 LDI Sent_Data, 'D'
		 CALL UART_Sending
		 LDI Sent_Data, '='
		 CALL UART_Sending
		 LDI Sent_Data, '1'
		 CALL UART_Sending
		 LDI Sent_Data, ','
		 CALL UART_Sending
		 LDI Sent_Data, '4'
		 CALL UART_Sending
		 LDI Sent_Data, 0b00001101
		 CALL UART_Sending
		 CALL Delay_20ms
		 LDI Temp1, 0
		 STS 0x0364, Temp1
		 RET


Read_ON_OFF:
        LDI Temp3, 0b00000000
		OUT PINB, Temp3
		IN Temp1, PORTB
		CBR Temp1, 15
		OUT PORTB, Temp1
		CALL Delay_20ms
		IN Temp1, PINB
		SBRC Temp1, 0
		SBR Temp3, 1
		CBR Temp1, 15
		SBR Temp1, 2
		OUT PORTB, Temp1
		CALL Delay_20ms
		IN Temp1, PINB
		SBRC Temp1, 0
		SBR Temp3, 2
		CBR Temp1, 15
		SBR Temp1, 4
		OUT PORTB, Temp1
		CALL Delay_20ms
		IN Temp1, PINB
		SBRC Temp1, 0
		SBR Temp3, 4
		CBR Temp1, 15
		SBR Temp1, 6
		OUT PORTB, Temp1
		CALL Delay_20ms
		IN Temp1, PINB
		SBRC Temp1, 0
		SBR Temp3, 8
		CBR Temp1, 15
		SBR Temp1, 8
		OUT PORTB, Temp1
		CALL Delay_20ms
		IN Temp1, PINB
		SBRC Temp1, 0
		SBR Temp3, 16
		CBR Temp1, 15
		SBR Temp1, 10
		OUT PORTB, Temp1
		CALL Delay_20ms
		IN Temp1, PINB
		SBRC Temp1, 0
		SBR Temp3, 32
		CBR Temp1, 15
		SBR Temp1, 12
		OUT PORTB, Temp1
		CALL Delay_20ms
		IN Temp1, PINB
		SBRC Temp1, 0
		SBR Temp3, 64
		CBR Temp1, 15
		SBR Temp1, 14
		OUT PORTB, Temp1
		CALL Delay_20ms
		IN Temp1, PINB
		SBRC Temp1, 0
		SBR Temp3, 128
	    STS 0x0220, Temp3
		RET


Time_For_Read_Temperatures:
                              LDS Temp1, 0x035A
		                      CP Minutes, Temp1
		                      BREQ Time_For_Read_Temperatures_05
			                  CP Minutes, Temp1
			                  BRGE Time_For_Read_Temperatures_02
			                  SUB Temp1, Minutes
			                  LDI Temp2, 44
			                  CP Temp2, Temp1
			                  BRGE Time_For_Read_Temperatures_04
			                  LDI Temp2, 45
			                  CP Temp2, Temp1
			                  BRGE Time_For_Read_Temperatures_01
			                  RJMP Time_For_Read_Temperatures_05
Time_For_Read_Temperatures_01:LDS Temp1, 0x035B
		                      CP Seconds, Temp1
				              BRGE Time_For_Read_Temperatures_04
							  RJMP Time_For_Read_Temperatures_05
Time_For_Read_Temperatures_02:LDS Temp1, 0x035A
				              MOV Temp2, Minutes
				              SUB Temp2, Temp1
				              LDI Temp1, 16
				              CP Temp2, Temp1
				              BRGE Time_For_Read_Temperatures_04
				              LDI Temp1, 15
				              CP Temp2, Temp1
				              BRGE Time_For_Read_Temperatures_03
				              RJMP Time_For_Read_Temperatures_05
Time_For_Read_Temperatures_03:LDS Temp1, 0x035B
		                      CP Seconds, Temp1
				              BRLT Time_For_Read_Temperatures_05
Time_For_Read_Temperatures_04:CALL Read_Temperatures
                              STS 0x035A, Minutes
				              STS 0x035B, Seconds
Time_For_Read_Temperatures_05:RET


Read_Temperatures:
                     IN Temp1, PORTA
		             CBR Temp1, 30
					 SBR Temp1, 2
		             OUT PORTA, Temp1
		             CALL Delay_1s
					 CLI
		             CALL Read_ADC
					 SEI
		             LDS Dec1, 0x0290
		             CALL Calibration_SUB
		             LDS Dec1, 0x0291
		             LDS Dec2, 0x0292
		             CALL Calibration_MUL
		             CALL Bin_to_Number
		             STS 0x0200, Dec2
		             STS 0x0201, Dec1
		             IN Temp1, PORTA
		             CBR Temp1, 30
                     SBR Temp1, 6
		             OUT PORTA, Temp1
		             CALL Delay_1s
		             CLI
		             CALL Read_ADC
					 SEI
		             LDS Dec1, 0x0293
		             CALL Calibration_SUB
		             LDS Dec1, 0x0294
		             LDS Dec2, 0x0295
		             CALL Calibration_MUL
		             CALL Bin_to_Number
		             STS 0x0202, Dec2
		             STS 0x0203, Dec1
		             IN Temp1, PORTA
		             CBR Temp1, 30
                     SBR Temp1, 10
		             OUT PORTA, Temp1
		             CALL Delay_1s
		             CLI
		             CALL Read_ADC
					 SEI
		             LDS Dec1, 0x0296
		             CALL Calibration_SUB
		             LDS Dec1, 0x0297
		             LDS Dec2, 0x0298
		             CALL Calibration_MUL
		             CALL Bin_to_Number
					 STS 0x0204, Dec2
					 STS 0x0205, Dec1
					 IN Temp1, PORTA
					 CBR Temp1, 30
					 SBR Temp1, 14
					 OUT PORTA, Temp1
					 CALL Delay_1s
					 CLI
		             CALL Read_ADC
					 SEI
					 LDS Dec1, 0x0299
					 CALL Calibration_SUB
					 LDS Dec1, 0x029A
					 LDS Dec2, 0x029B
					 CALL Calibration_MUL
					 CALL Bin_to_Number
					 STS 0x0206, Dec2
					 STS 0x0207, Dec1
					 IN Temp1, PORTA
					 CBR Temp1, 30
					 SBR Temp1, 18
					 OUT PORTA, Temp1
					 CALL Delay_1s
					 CLI
		             CALL Read_ADC
					 SEI
					 LDS Dec1, 0x029C
					 CALL Calibration_SUB
					 LDS Dec1, 0x029D
					 LDS Dec2, 0x029E
					 CALL Calibration_MUL
					 CALL Bin_to_Number
					 STS 0x0208, Dec2
					 STS 0x0209, Dec1
					 IN Temp1, PORTA
					 CBR Temp1, 30
					 SBR Temp1, 22
					 OUT PORTA, Temp1
					 CALL Delay_1s
					 CLI
		             CALL Read_ADC
					 SEI
					 LDS Dec1, 0x029F
					 CALL Calibration_SUB
					 LDS Dec1, 0x02A0
					 LDS Dec2, 0x02A1
					 CALL Calibration_MUL
					 CALL Bin_to_Number
					 STS 0x020A, Dec2
					 STS 0x020B, Dec1
					 IN Temp1, PORTA
					 CBR Temp1, 30
					 SBR Temp1, 26
					 OUT PORTA, Temp1
					 CALL Delay_1s
					 CLI
		             CALL Read_ADC
					 SEI
					 LDS Dec1, 0x02A2
					 CALL Calibration_SUB
					 LDS Dec1, 0x02A3
					 LDS Dec2, 0x02A4
					 CALL Calibration_MUL
					 CALL Bin_to_Number
					 STS 0x020C, Dec2
					 STS 0x020D, Dec1
					 IN Temp1, PORTA
					 CBR Temp1, 30
					 SBR Temp1, 30
					 OUT PORTA, Temp1
					 CALL Delay_1s
					 CLI
		             CALL Read_ADC
					 SEI
					 LDS Dec1, 0x02A5
					 CALL Calibration_SUB
					 LDS Dec1, 0x02A6
					 LDS Dec2, 0x02A7
					 CALL Calibration_MUL
					 CALL Bin_to_Number
					 STS 0x020E, Dec2
					 STS 0x020F, Dec1
					 IN Temp1, PORTA
					 CBR Temp1, 30
					 OUT PORTA, Temp1
					 RET

Compare_Temperatures:
                        LDI Temp1, 0
						STS 0x030A, Temp1
						LDS Temp1, 0x0200
						LDS Temp2, 0x0230
		                CP Temp1, Temp2
		                BRLT Compare_Temperatures_01
						CP Temp2, Temp1
						BRLT Compare_Temperatures_02
						LDS Temp1, 0x0201
						LDS Temp2, 0x0231
						CP Temp1, Temp2
		                BRGE Compare_Temperatures_02
Compare_Temperatures_01:LDS Temp1, 0x030A
                        LDI Temp2, 0b00000001
                        OR Temp1, Temp2
						STS 0x030A, Temp1
Compare_Temperatures_02:LDI Temp1, 0
						STS 0x030A, Temp1
						LDS Temp1, 0x0200
						LDS Temp2, 0x0232
		                CP Temp2, Temp1
		                BRLT Compare_Temperatures_03
						CP Temp1, Temp2
						BRLT Compare_Temperatures_04
						LDS Temp1, 0x0201
						LDS Temp2, 0x0233
						CP Temp2, Temp1
		                BRGE Compare_Temperatures_04
Compare_Temperatures_03:LDS Temp1, 0x030A
                        LDI Temp2, 0b00000001
                        OR Temp1, Temp2
						STS 0x030A, Temp1

Compare_Temperatures_04:LDS Temp1, 0x0202
						LDS Temp2, 0x0234
		                CP Temp1, Temp2
		                BRLT Compare_Temperatures_05
						CP Temp2, Temp1
						BRLT Compare_Temperatures_06
						LDS Temp1, 0x0203
						LDS Temp2, 0x0235
						CP Temp1, Temp2
		                BRGE Compare_Temperatures_06
Compare_Temperatures_05:LDS Temp1, 0x030A
                        LDI Temp2, 0b00000010
                        OR Temp1, Temp2
						STS 0x030A, Temp1
Compare_Temperatures_06:LDI Temp1, 0
						STS 0x030A, Temp1
						LDS Temp1, 0x0202
						LDS Temp2, 0x0236
		                CP Temp2, Temp1
		                BRLT Compare_Temperatures_07
						CP Temp1, Temp2
						BRLT Compare_Temperatures_08
						LDS Temp1, 0x0203
						LDS Temp2, 0x0237
						CP Temp2, Temp1
		                BRGE Compare_Temperatures_08
Compare_Temperatures_07:LDS Temp1, 0x030A
                        LDI Temp2, 0b00000010
                        OR Temp1, Temp2
						STS 0x030A, Temp1

Compare_Temperatures_08:LDS Temp1, 0x0204
						LDS Temp2, 0x0238
		                CP Temp1, Temp2
		                BRLT Compare_Temperatures_09
						CP Temp2, Temp1
						BRLT Compare_Temperatures_10
						LDS Temp1, 0x0205
						LDS Temp2, 0x0239
						CP Temp1, Temp2
		                BRGE Compare_Temperatures_10
Compare_Temperatures_09:LDS Temp1, 0x030A
                        LDI Temp2, 0b00000100
                        OR Temp1, Temp2
						STS 0x030A, Temp1
Compare_Temperatures_10:LDI Temp1, 0
						STS 0x030A, Temp1
						LDS Temp1, 0x0204
						LDS Temp2, 0x023A
		                CP Temp2, Temp1
		                BRLT Compare_Temperatures_11
						CP Temp1, Temp2
						BRLT Compare_Temperatures_12
						LDS Temp1, 0x0205
						LDS Temp2, 0x023B
						CP Temp2, Temp1
		                BRGE Compare_Temperatures_12
Compare_Temperatures_11:LDS Temp1, 0x030A
                        LDI Temp2, 0b00000100
                        OR Temp1, Temp2
						STS 0x030A, Temp1

Compare_Temperatures_12:LDS Temp1, 0x0206
						LDS Temp2, 0x023C
		                CP Temp1, Temp2
		                BRLT Compare_Temperatures_13
						CP Temp2, Temp1
						BRLT Compare_Temperatures_14
						LDS Temp1, 0x0207
						LDS Temp2, 0x023D
						CP Temp1, Temp2
		                BRGE Compare_Temperatures_14
Compare_Temperatures_13:LDS Temp1, 0x030A
                        LDI Temp2, 0b00001000
                        OR Temp1, Temp2
						STS 0x030A, Temp1
Compare_Temperatures_14:LDI Temp1, 0
						STS 0x030A, Temp1
						LDS Temp1, 0x0206
						LDS Temp2, 0x023E
		                CP Temp2, Temp1
		                BRLT Compare_Temperatures_15
						CP Temp1, Temp2
						BRLT Compare_Temperatures_16
						LDS Temp1, 0x0207
						LDS Temp2, 0x023F
						CP Temp2, Temp1
		                BRGE Compare_Temperatures_16
Compare_Temperatures_15:LDS Temp1, 0x030A
                        LDI Temp2, 0b00001000
                        OR Temp1, Temp2
						STS 0x030A, Temp1

Compare_Temperatures_16:LDS Temp1, 0x0208
						LDS Temp2, 0x0240
		                CP Temp1, Temp2
		                BRLT Compare_Temperatures_17
						CP Temp2, Temp1
						BRLT Compare_Temperatures_18
						LDS Temp1, 0x0209
						LDS Temp2, 0x0241
						CP Temp1, Temp2
		                BRGE Compare_Temperatures_18
Compare_Temperatures_17:LDS Temp1, 0x030A
                        LDI Temp2, 0b00010000
                        OR Temp1, Temp2
						STS 0x030A, Temp1
Compare_Temperatures_18:LDI Temp1, 0
						STS 0x030A, Temp1
						LDS Temp1, 0x0208
						LDS Temp2, 0x0242
		                CP Temp2, Temp1
		                BRLT Compare_Temperatures_19
						CP Temp1, Temp2
						BRLT Compare_Temperatures_20
						LDS Temp1, 0x0209
						LDS Temp2, 0x0243
						CP Temp2, Temp1
		                BRGE Compare_Temperatures_20
Compare_Temperatures_19:LDS Temp1, 0x030A
                        LDI Temp2, 0b00010000
                        OR Temp1, Temp2
						STS 0x030A, Temp1

Compare_Temperatures_20:LDS Temp1, 0x020A
						LDS Temp2, 0x0244
		                CP Temp1, Temp2
		                BRLT Compare_Temperatures_21
						CP Temp2, Temp1
						BRLT Compare_Temperatures_22
						LDS Temp1, 0x020B
						LDS Temp2, 0x0245
						CP Temp1, Temp2
		                BRGE Compare_Temperatures_22
Compare_Temperatures_21:LDS Temp1, 0x030A
                        LDI Temp2, 0b00100000
                        OR Temp1, Temp2
						STS 0x030A, Temp1
Compare_Temperatures_22:LDI Temp1, 0
						STS 0x030A, Temp1
						LDS Temp1, 0x020A
						LDS Temp2, 0x0246
		                CP Temp2, Temp1
		                BRLT Compare_Temperatures_23
						CP Temp1, Temp2
						BRLT Compare_Temperatures_24
						LDS Temp1, 0x020B
						LDS Temp2, 0x0247
						CP Temp2, Temp1
		                BRGE Compare_Temperatures_24
Compare_Temperatures_23:LDS Temp1, 0x030A
                        LDI Temp2, 0b00100000
                        OR Temp1, Temp2
						STS 0x030A, Temp1

Compare_Temperatures_24:LDS Temp1, 0x020C
						LDS Temp2, 0x0248
		                CP Temp1, Temp2
		                BRLT Compare_Temperatures_25
						CP Temp2, Temp1
						BRLT Compare_Temperatures_26
						LDS Temp1, 0x020D
						LDS Temp2, 0x0249
						CP Temp1, Temp2
		                BRGE Compare_Temperatures_26
Compare_Temperatures_25:LDS Temp1, 0x030A
                        LDI Temp2, 0b01000000
                        OR Temp1, Temp2
						STS 0x030A, Temp1
Compare_Temperatures_26:LDI Temp1, 0
						STS 0x030A, Temp1
						LDS Temp1, 0x020C
						LDS Temp2, 0x024A
		                CP Temp2, Temp1
		                BRLT Compare_Temperatures_27
						CP Temp1, Temp2
						BRLT Compare_Temperatures_28
						LDS Temp1, 0x020D
						LDS Temp2, 0x024B
						CP Temp2, Temp1
		                BRGE Compare_Temperatures_28
Compare_Temperatures_27:LDS Temp1, 0x030A
                        LDI Temp2, 0b01000000
                        OR Temp1, Temp2
						STS 0x030A, Temp1

Compare_Temperatures_28:LDS Temp1, 0x020E
						LDS Temp2, 0x024C
		                CP Temp1, Temp2
		                BRLT Compare_Temperatures_29
						CP Temp2, Temp1
						BRLT Compare_Temperatures_30
						LDS Temp1, 0x020F
						LDS Temp2, 0x024D
						CP Temp1, Temp2
		                BRGE Compare_Temperatures_30
Compare_Temperatures_29:LDS Temp1, 0x030A
                        LDI Temp2, 0b10000000
                        OR Temp1, Temp2
						STS 0x030A, Temp1
Compare_Temperatures_30:LDI Temp1, 0
						STS 0x030A, Temp1
						LDS Temp1, 0x020E
						LDS Temp2, 0x024E
		                CP Temp2, Temp1
		                BRLT Compare_Temperatures_31
						CP Temp1, Temp2
						BRLT Compare_Temperatures_32
						LDS Temp1, 0x020F
						LDS Temp2, 0x024F
						CP Temp2, Temp1
		                BRGE Compare_Temperatures_32
Compare_Temperatures_31:LDS Temp1, 0x030A
                        LDI Temp2, 0b10000000
                        OR Temp1, Temp2
						STS 0x030A, Temp1
Compare_Temperatures_32:RET


Compare_ON_OFF:
                  LDS Temp1, 0x0220
				  LDS Temp2, 0x0270
				  EOR Temp1,Temp2
				  STS 0x030D, Temp1
				  RET


Compare_Switches:
                    LDS Temp1, 0x0280
				    IN Temp2, PORTC
		            CP Temp1, Temp2
					BREQ Compare_Switches_01
					OUT PORTC, Temp1
Compare_Switches_01:RET


Send_Warning_Message:
                        LDS Temp1, 0x030A
						CPI Temp1, 0
						BRNE Send_Warning_Message_00
						LDS Temp1, 0x030D
						CPI Temp1, 0
						BRNE Send_Warning_Message_00
						RET
Send_Warning_Message_00:SBRC Not_Allow_Communication,0
				        RET
						LDS Temp1, 0x0323
						LDS Temp2, 0x0316
						OR Temp2, Temp1
						LDS Temp1, 0x030A
						EOR Temp2, Temp1
						AND Temp2, Temp1
						STS 0x0330, Temp2
						LDS Temp1, 0x0326
						LDS Temp2, 0x0319
						OR Temp2, Temp1
						LDS Temp1, 0x030D
						EOR Temp2, Temp1
						AND Temp2, Temp1
						STS 0x0333, Temp2
						CPI Temp2, 0
						BRNE Send_Warning_Message_01
						LDS Temp2, 0x0330
						CPI Temp2, 0
						BRNE Send_Warning_Message_01
						RET
Send_Warning_Message_01:MOV Temp1, Data_Completement_Flag
				        CPI Temp1, 0b10000000
				        BREQ Send_Warning_Message_02
				        LDI Temp1, 0
				        MOV Counter_03, Temp1
				        RET
Send_Warning_Message_02:INC Counter_03
                        CPI Counter_03, 0b00100000
					    BREQ Send_Warning_Message_03
					    RET
Send_Warning_Message_03:LDI Temp1, 0
				        MOV Counter_03, Temp1
						CALL Send_Message
						LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, 'A'
		                CALL UART_Sending
					    LDI Sent_Data, 'R'
		                CALL UART_Sending
					    LDI Sent_Data, 'N'
		                CALL UART_Sending
					    LDI Sent_Data, 'I'
		                CALL UART_Sending
						LDI Sent_Data, 'N'
		                CALL UART_Sending
						LDI Sent_Data, 'G'
		                CALL UART_Sending
						LDI Sent_Data, ':'
		                CALL UART_Sending
						LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_04:LDS Temp1, 0x030A
					    SBRS Temp1, 0
						RJMP Send_Warning_Message_05
					    LDI Sent_Data, 'T'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '0'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Sent_Data, 0x0200
					    CALL UART_Sending
					    LDS Sent_Data, 0x0201
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_05:LDS Temp1, 0x030A
					    SBRS Temp1, 1
						RJMP Send_Warning_Message_06
					    LDI Sent_Data, 'T'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '1'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Sent_Data, 0x0202
					    CALL UART_Sending
					    LDS Sent_Data, 0x0203
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_06:LDS Temp1, 0x030A
					    SBRS Temp1, 2
						RJMP Send_Warning_Message_07
					    LDI Sent_Data, 'T'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '2'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Sent_Data, 0x0204
					    CALL UART_Sending
					    LDS Sent_Data, 0x0205
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_07:LDS Temp1, 0x030A
					    SBRS Temp1, 3
						RJMP Send_Warning_Message_08
					    LDI Sent_Data, 'T'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '3'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Sent_Data, 0x0206
					    CALL UART_Sending
					    LDS Sent_Data, 0x0207
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_08:LDS Temp1, 0x030A
					    SBRS Temp1, 4
						RJMP Send_Warning_Message_09
					    LDI Sent_Data, 'T'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '4'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Sent_Data, 0x0208
					    CALL UART_Sending
					    LDS Sent_Data, 0x0209
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_09:LDS Temp1, 0x030A
					    SBRS Temp1, 5
						RJMP Send_Warning_Message_10
					    LDI Sent_Data, 'T'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '5'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Sent_Data, 0x020A
					    CALL UART_Sending
					    LDS Sent_Data, 0x020B
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_10:LDS Temp1, 0x030A
					    SBRS Temp1, 6
						RJMP Send_Warning_Message_11
					    LDI Sent_Data, 'T'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '6'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Sent_Data, 0x020C
					    CALL UART_Sending
					    LDS Sent_Data, 0x020D
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_11:LDS Temp1, 0x030A
					    SBRS Temp1, 7
						RJMP Send_Warning_Message_12
					    LDI Sent_Data, 'T'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '7'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Sent_Data, 0x020E
					    CALL UART_Sending
					    LDS Sent_Data, 0x020F
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_12:LDS Temp1, 0x030D
					    SBRS Temp1, 0
						RJMP Send_Warning_Message_13
					    LDI Sent_Data, 'P'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '0'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Temp1, 0x0220
					    LDI Sent_Data, 'F'
					    SBRC Temp1, 0
					    LDI Sent_Data, 'N'
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_13:LDS Temp1, 0x030D
					    SBRS Temp1, 1
						RJMP Send_Warning_Message_14
					    LDI Sent_Data, 'P'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '1'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Temp1, 0x0220
					    LDI Sent_Data, 'F'
					    SBRC Temp1, 1
					    LDI Sent_Data, 'N'
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_14:LDS Temp1, 0x030D
					    SBRS Temp1, 2
						RJMP Send_Warning_Message_15
					    LDI Sent_Data, 'P'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '2'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Temp1, 0x0220
					    LDI Sent_Data, 'F'
					    SBRC Temp1, 2
					    LDI Sent_Data, 'N'
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_15:LDS Temp1, 0x030D
					    SBRS Temp1, 3
						RJMP Send_Warning_Message_16
					    LDI Sent_Data, 'P'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '3'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Temp1, 0x0220
					    LDI Sent_Data, 'F'
					    SBRC Temp1, 3
					    LDI Sent_Data, 'N'
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_16:LDS Temp1, 0x030D
					    SBRS Temp1, 4
						RJMP Send_Warning_Message_17
					    LDI Sent_Data, 'P'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '4'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Temp1, 0x0220
					    LDI Sent_Data, 'F'
					    SBRC Temp1, 4
					    LDI Sent_Data, 'N'
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_17:LDS Temp1, 0x030D
					    SBRS Temp1, 5
						RJMP Send_Warning_Message_18
					    LDI Sent_Data, 'P'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '5'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Temp1, 0x0220
					    LDI Sent_Data, 'F'
					    SBRC Temp1, 5
					    LDI Sent_Data, 'N'
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_18:LDS Temp1, 0x030D
					    SBRS Temp1, 6
						RJMP Send_Warning_Message_19
					    LDI Sent_Data, 'P'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '6'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Temp1, 0x0220
					    LDI Sent_Data, 'F'
					    SBRC Temp1, 6
					    LDI Sent_Data, 'N'
					    CALL UART_Sending
					    LDI Sent_Data, 0b00001101
		                CALL UART_Sending
Send_Warning_Message_19:LDS Temp1, 0x030D
					    SBRS Temp1, 7
						RJMP Send_Warning_Message_20
					    LDI Sent_Data, 'P'
		                CALL UART_Sending
					    LDI Sent_Data, 'W'
		                CALL UART_Sending
					    LDI Sent_Data, '7'
		                CALL UART_Sending
					    LDI Sent_Data, ':'
		                CALL UART_Sending
					    LDS Temp1, 0x0220
					    LDI Sent_Data, 'F'
					    SBRC Temp1, 7
					    LDI Sent_Data, 'N'
					    CALL UART_Sending
Send_Warning_Message_20:LDI Sent_Data, 0b00011010
					    CALL UART_Sending
                        LDI Temp1, 0b00000001
                        OR Not_Allow_Communication, Temp1
						LDS Temp1, 0x0330
						STS 0x0329, Temp1
						LDS Temp1, 0x0333
						STS 0x032C, Temp1
						LDI Temp1, 0b00000100
					    STS 0x0302, Temp1
					    STS 0x0307, Minutes
					    STS 0x0308, Seconds
						STS 0x0300, Minutes
						STS 0x0301, Seconds
					    RET


Warning_Message_Management:
                              LDS Temp1, 0x0309
							  SBRS Temp1, 2
							  RJMP Warning_Message_Management_000
							  LDI Temp1, 0
							  STS 0x0309, Temp1
							  LDS Temp1, 0x0329
							  LDS Temp2, 0x0310
							  OR Temp1, Temp2
							  STS 0x0310, Temp1
							  LDS Temp1, 0x032C
							  LDS Temp2, 0x0313
							  OR Temp1, Temp2
							  STS 0x0313, Temp1
							  LDI Temp1, 0b00000001
							  STS 0x0365, Temp1
Warning_Message_Management_000:LDS Temp1, 0x0365
                              CPI Temp1, 0
							  BREQ Warning_Message_Management_05
Warning_Message_Management_00:LDS Temp1, 0x0307
		                      CP Minutes, Temp1
		                      BREQ Warning_Message_Management_04
			                  CP Minutes, Temp1
			                  BRGE Warning_Message_Management_02
			                  SUB Temp1, Minutes
			                  LDI Temp2, 49
			                  CP Temp2, Temp1
			                  BRGE Warning_Message_Management_05
			                  LDI Temp2, 50
			                  CP Temp2, Temp1
			                  BRGE Warning_Message_Management_01
			                  RJMP Warning_Message_Management_04
Warning_Message_Management_01:LDS Temp1, 0x0308
		                      CP Seconds, Temp1
				              BRGE Warning_Message_Management_05
							  RJMP Warning_Message_Management_04
Warning_Message_Management_02:LDS Temp1, 0x0307
				              MOV Temp2, Minutes
				              SUB Temp2, Temp1
				              LDI Temp1, 11
				              CP Temp2, Temp1
				              BRGE Warning_Message_Management_05
				              LDI Temp1, 10
				              CP Temp2, Temp1
				              BRGE Warning_Message_Management_03
				              RJMP Warning_Message_Management_04
Warning_Message_Management_03:LDS Temp1, 0x0308
		                      CP Seconds, Temp1
				              BRGE Warning_Message_Management_05
Warning_Message_Management_04:LDS Temp1, 0x0310
                              STS 0x0323, Temp1
							  LDS Temp1, 0x0313
                              STS 0x0326, Temp1
                              RET
Warning_Message_Management_05:LDI Temp1, 0
                              STS 0x0323, Temp1
							  LDI Temp1, 0
                              STS 0x0326, Temp1
							  LDI Temp1, 0
							  STS 0x0365, Temp1
				              RET


Init_ADC:
         ldi Temp1, 0b00100000
         out ADMUX, Temp1
         ldi Temp1, 0b10001110
	     out ADCSRA, Temp1
		 ret


Read_ADC:
              sbi ADCSRA,ADSC
Read_ADCWait: sbis ADCSRA, ADIF
              rjmp Read_ADCWait
	          sbi ADCSRA, ADIF
	          in DigitalData1,ADCH
	          ret


Calibration_SUB:
           SUB DigitalData1, Dec1
		   ret


Calibration_MUL:
           MUL DigitalData1, Dec1
		   MOVW Temp2:Temp1, r1:r0
		   MUL DigitalData1, Dec2
		   ADD Temp2, r0
		   ADC Temp3, r1
		   ret


Bin_to_Number:
				  LDI Temp1, $00
				  MOV Dec1, Temp1
				  MOV Dec2, Temp1
Bin_to_Number_01: CPI Temp3, 0b00001111
                  BREQ Bin_to_Number_011
				  CPI Temp3, 0b00001111
                  BRLO Bin_to_Number_02
				  RJMP Bin_to_Number_014
Bin_to_Number_011:CPI Temp2, 0b01000010
                  BREQ Bin_to_Number_012
                  CPI Temp2, 0b01000010
				  BRLO Bin_to_Number_02
				  RJMP Bin_to_Number_014
Bin_to_Number_012:CPI Temp1, 0b01000000
                  BRLO Bin_to_Number_02
Bin_to_Number_014:SUBI Temp1, 0b01000000
                  SBCI Temp2, 0b01000010
				  SBCI Temp3, 0b00001111
                  INC Dec2
				  RJMP Bin_to_Number_01
Bin_to_Number_02: CPI Temp3, 0b00000001
                  BREQ Bin_to_Number_021
				  CPI Temp3, 0b00000001
                  BRLO Bin_to_Number_04
				  RJMP Bin_to_Number_024
Bin_to_Number_021:CPI Temp2, 0b10000110
                  BREQ Bin_to_Number_022
                  CPI Temp2, 0b10000110
				  BRLO Bin_to_Number_04
				  RJMP Bin_to_Number_024
Bin_to_Number_022:CPI Temp1, 0b10100000
                  BRLO Bin_to_Number_04
Bin_to_Number_024:SUBI Temp1, 0b10100000
                  SBCI Temp2, 0b10000110
				  SBCI Temp3, 0b00000001
                  INC Dec1
				  RJMP Bin_to_Number_02
Bin_to_Number_04: LDI Temp1, 0b00110000
                  OR Dec1, Temp1
				  LDI Temp1, 0b00110000
                  OR Dec2, Temp1
				  RET


Check_Modem:
			   SBRC Not_Allow_Communication, 0
			   RET
Check_Modem_00:LDS Temp1, 0x031D
		       CP Minutes, Temp1
		       BREQ Check_Modem_05
			   CP Minutes, Temp1
			   BRGE Check_Modem_02
			   SUB Temp1, Minutes
			   LDI Temp2, 49
			   CP Temp2, Temp1
			   BRGE Check_Modem_04
			   LDI Temp2, 50
			   CP Temp2, Temp1
			   BRGE Check_Modem_01
			   RJMP Check_Modem_05
Check_Modem_01:LDS Temp1, 0x031E
		       CP Seconds, Temp1
			   BRGE Check_Modem_04
			   RJMP Check_Modem_05
Check_Modem_02:LDS Temp1, 0x031D
			   MOV Temp2, Minutes
			   SUB Temp2, Temp1
			   LDI Temp1, 11
			   CP Temp2, Temp1
			   BRGE Check_Modem_04
			   LDI Temp1, 10
			   CP Temp2, Temp1
			   BRGE Check_Modem_03
			   RJMP Check_Modem_05
Check_Modem_03:LDS Temp1, 0x031E
		       CP Seconds, Temp1
			   BRLT Check_Modem_05
Check_Modem_04:CALL Send_AT_For_Check
               LDI Temp1, 0b00000001
			   STS 0x031C, Temp1
			   STS 0x031D, Minutes
			   STS 0x031E, Seconds
Check_Modem_05:RET


Send_AT_For_Check:
			   LDI Sent_Data, 'A'
		       CALL UART_Sending
		       LDI Sent_Data, 'T'
		       CALL UART_Sending
			   LDI Sent_Data, 0b00001101
		       CALL UART_Sending
			   RET


Wait_For_AT_Answer:
					  LDS Temp1, 0x031C
					  SBRS Temp1, 0
					  RET
Wait_For_AT_Answer_00:LDS Temp1, 0x031D
		              CP Minutes, Temp1
		              BREQ Wait_For_AT_Answer_04
			          CP Minutes, Temp1
			          BRGE Wait_For_AT_Answer_02
			          SUB Temp1, Minutes
			          LDI Temp2, 58
			          CP Temp2, Temp1
			          BRGE Wait_For_AT_Answer_05
			          LDI Temp2, 59
			          CP Temp2, Temp1
			          BRGE Wait_For_AT_Answer_01
			          RJMP Wait_For_AT_Answer_04
Wait_For_AT_Answer_01:LDS Temp1, 0x031E
		              CP Seconds, Temp1
				      BRGE Wait_For_AT_Answer_05
					  RJMP Wait_For_AT_Answer_04
Wait_For_AT_Answer_02:LDS Temp1, 0x031D
				      MOV Temp2, Minutes
				      SUB Temp2, Temp1
				      LDI Temp1, 2
				      CP Temp2, Temp1
				      BRGE Wait_For_AT_Answer_05
			  	      LDI Temp1, 1
				      CP Temp2, Temp1
				      BRGE Wait_For_AT_Answer_03
				      RJMP Wait_For_AT_Answer_04
Wait_For_AT_Answer_03:LDS Temp1, 0x031E
		              CP Seconds, Temp1
				      BRGE Wait_For_AT_Answer_05
Wait_For_AT_Answer_04:SBRS Data_Analysis_Flag, 1
                      RET
					  LDI Temp1, 0b00000000
			          STS 0x031C, Temp1
					  LDI Temp1, 0b11111101
                      AND Data_Analysis_Flag, Temp1
					  RET
Wait_For_AT_Answer_05:LDI Temp1, 0b00000001
                      STS 0x031F, Temp1
					  LDI Temp1, 0b00000000
			          STS 0x031C, Temp1
					  RET


Restart_Modem:
				 LDS Temp1, 0x031F
			     SBRS Temp1, 0
				 RET
				 CBI PORTA, 5
				 CALL Delay_1s
				 SBI PORTA, 5
				 STS 0x0320, Minutes
				 STS 0x0321, Seconds
				 LDI Temp1, 0b00000001
				 MOV Not_Allow_Communication, Temp1
				 STS 0x0322, Temp1
				 LDI Temp1, 0b00000000
			     STS 0x031F, Temp1
				 RET


Wait_For_Startup:
					LDS Temp1, 0x0322
			        SBRS Temp1, 0
					RET
					LDS Temp1, 0x0320
		            CP Minutes, Temp1
		            BREQ Wait_For_Startup_05
			        CP Minutes, Temp1
			        BRGE Wait_For_Startup_02
			        SUB Temp1, Minutes
			        LDI Temp2, 58
			        CP Temp2, Temp1
			        BRGE Wait_For_Startup_04
			        LDI Temp2, 59
			        CP Temp2, Temp1
			        BRGE Wait_For_Startup_01
			        RJMP Wait_For_Startup_05
Wait_For_Startup_01:LDS Temp1, 0x0321
		            CP Seconds, Temp1
			        BRGE Wait_For_Startup_04
					RJMP Wait_For_Startup_05
Wait_For_Startup_02:LDS Temp1, 0x0320
			        MOV Temp2, Minutes
			        SUB Temp2, Temp1
			        LDI Temp1, 2
			        CP Temp2, Temp1
			        BRGE Wait_For_Startup_04
			        LDI Temp1, 1
			        CP Temp2, Temp1
			        BRGE Wait_For_Startup_03
			        RJMP Wait_For_Startup_05
Wait_For_Startup_03:LDS Temp1, 0x0321
		            CP Seconds, Temp1
			        BRLT Wait_For_Startup_05
Wait_For_Startup_04:LDI Temp1, 0b00000000
			        MOV Not_Allow_Communication, Temp1
			        STS 0x0322, Temp1
					LDI LCD_Data_Buffer, 'K'
					CALL LCD_Data
Wait_For_Startup_05:RET


Init_LCD:
   ldi LCD_Command_Buffer, 0b00101000
   CALL LCD_Command
   ldi LCD_Command_Buffer, 0b00001100
   CALL LCD_Command
   ldi LCD_Command_Buffer, 0b00000110
   CALL LCD_Command
   ldi LCD_Command_Buffer, 0b00000001
   CALL LCD_Command
   ret


Reset_LCD:
   CALL Delay_20ms
   CALL Delay_20ms
   CBR LCD_Command_Buffer, $FF
   SBR LCD_Command_Buffer, $30
   out PORTD,LCD_Command_Buffer
   cbi PORTD,2
   sbi PORTD,3
   cbi PORTD,3
   CALL Delay_20ms
   CBR LCD_Command_Buffer, $FF
   SBR LCD_Command_Buffer, $30
   out PORTD,LCD_Command_Buffer
   cbi PORTD,2
   sbi PORTD,3
   cbi PORTD,3
   CALL Delay_20ms
   CBR LCD_Command_Buffer, $FF
   SBR LCD_Command_Buffer, $30
   out PORTD,LCD_Command_Buffer
   cbi PORTD,2
   sbi PORTD,3
   cbi PORTD,3
   CALL Delay_20ms
   CBR LCD_Command_Buffer, $FF
   SBR LCD_Command_Buffer, $20
   out PORTD,LCD_Command_Buffer
   cbi PORTD,2
   sbi PORTD,3
   cbi PORTD,3
   CALL Delay_20ms
   ret


LCD_Command:
         mov Temp1, LCD_Command_Buffer
         CBR LCD_Command_Buffer, $0F
         out PORTD,LCD_Command_Buffer
         cbi PORTD,2
         sbi PORTD,3
         cbi PORTD,3
         mov LCD_Command_Buffer, Temp1
         CBR LCD_Command_Buffer, $F0
         LSL LCD_Command_Buffer
         LSL LCD_Command_Buffer
         LSL LCD_Command_Buffer
         LSL LCD_Command_Buffer
         out PORTD,LCD_Command_Buffer
         cbi PORTD,2
         sbi PORTD,3
         cbi PORTD,3
         CALL Delay_20ms
         ret


LCD_Data:
            CPI LCD_Counter,$10
		    BRNE LCD_Data01
		    ldi LCD_Command_Buffer, $C0
            CALL LCD_Command
LCD_Data01:	CPI LCD_Counter,$20
		    BRNE LCD_Data02
			ldi LCD_Command_Buffer, $80
            CALL LCD_Command
		    LDI LCD_Counter,0
LCD_Data02: mov Temp1, LCD_Data_Buffer
            CBR LCD_Data_Buffer, $0F
	   	    SBR LCD_Data_Buffer, $04
            out PORTD,LCD_Data_Buffer
            sbi PORTD,2
            sbi PORTD,3
            cbi PORTD,3
            mov LCD_Data_Buffer, Temp1
            CBR LCD_Data_Buffer, $F0
            LSL LCD_Data_Buffer
            LSL LCD_Data_Buffer
            LSL LCD_Data_Buffer
            LSL LCD_Data_Buffer
		    SBR LCD_Data_Buffer, $04
            out PORTD,LCD_Data_Buffer
            sbi PORTD,2
            sbi PORTD,3
            cbi PORTD,3
		    INC LCD_Counter
            CALL Delay_20ms
            ret


Delay_20ms:
           ldi Temp1, 50
OuterLoop1:ldi Temp2, 255
InnerLoop1:nop
           nop
	       nop
		   nop
		   nop
		   nop
		   nop
		   nop
		   dec Temp2
		   brne InnerLoop1
		   dec Temp1
		   brne OuterLoop1
		   ret


Delay_1s:
           ldi Temp1, 11
OuterLoop2:ldi Temp2, 255
Loop2:     ldi Temp3, 255
InnerLoop2:nop
           nop
	       nop
		   nop
		   nop
		   nop
		   nop
		   nop
		   dec Temp3
		   brne InnerLoop2
		   dec Temp2
		   brne Loop2
		   dec Temp1
		   brne OuterLoop2
		   ret
