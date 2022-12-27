USE [msdb]
GO

/****** Object:  Job [DTS_MAILING_WELCOME]    Script Date: 27/12/2022 09:49:38 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 27/12/2022 09:49:38 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DTS_MAILING_WELCOME', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'DTS_MAILING_WELCOME', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DTS_MAILING_WELCOME]    Script Date: 27/12/2022 09:49:38 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DTS_MAILING_WELCOME', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=4, 
		@on_fail_step_id=3, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'DTSRun /S "portalcrcdb" /N "DTS_MAILING_WELCOME" /E /ADELTA = 1
', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email_Sucesso]    Script Date: 27/12/2022 09:49:38 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email_Sucesso', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'DTSRun /S "PORTALCRCDB" /N "Email" /ADe="Portal_CRC <portacrc@timbrasil.com.br>" /APara="msobrinho@timbrasil.com.br;sfreires@timbrasil.com.br;escruz@timbrasil.com.br;" /ACCO="" /AAssunto="IMPORTAÇÃO MAILING WELCOME - SUCESSO" /AMsg="<HTML><BODY STYLE=''FONT-SIZE= 10pt; FONT-FAMILY= Verdana;''><P>Senhores,</P><BR><BLOCKQUOTE>O processo "DTS_MAILING_WELCOME" foi finalizado com sucesso.</BLOCKQUOTE><P><BR></P><P><BR></P><P>At.</P><P><SPAN style=''FONT-SIZE= 7.5pt; COLOR= gray; mso-no-proof= yes''><B>PortalCRC</B><BR> TIM - Você sem fronteiras</SPAN></P></BODY></HTML>" /E
', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email_Falha]    Script Date: 27/12/2022 09:49:38 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email_Falha', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'DTSRun /S "PORTALCRCDB" /N "Email" /ADe="Portal_CRC <portacrc@timbrasil.com.br>" /APara="msobrinho@timbrasil.com.br;sfreires@timbrasil.com.br;escruz@timbrasil.com.br;" /ACCO="" /AAssunto="IMPORTAÇÃO MAILING WELCOME - FALHA" /AMsg="<HTML><BODY STYLE=''FONT-SIZE= 10pt; FONT-FAMILY= Verdana;''><P>Senhores,</P><BR><BLOCKQUOTE>Ocorreu uma falha no processo "DTS_MAILING_WELCOME" favor verificar os logs no servidor SNEDCVDB12.</BLOCKQUOTE><P><BR></P><P><BR></P><P>At.</P><P><SPAN style=''FONT-SIZE= 7.5pt; COLOR= gray; mso-no-proof= yes''><B>PortalCRC</B><BR> TIM - Você sem fronteiras</SPAN></P></BODY></HTML>" /E
', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'TODA-QUARTA-FEIRA', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=127, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20211206, 
		@active_end_date=99991231, 
		@active_start_time=140000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO