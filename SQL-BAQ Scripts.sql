--query with calculated date field
select 
	[PORel].[PONum] as [PORel_PONum],
	[PORel].[POLine] as [PORel_POLine],
	[PORel].[PORelNum] as [PORel_PORelNum],
	[POHeader].[OrderDate] as [POHeader_OrderDate],
	[PartTran].[TranDate] as [PartTran_TranDate],
	(datediff(day, POHeader.OrderDate, Parttran.TranDate)) as [Calculated_LeadTime],
	[Vendor].[Name] as [Vendor_Name],
	[Part].[ClassID] as [Part_ClassID],
	[POHeader].[BuyerID] as [POHeader_BuyerID],
	[Vendor].[State] as [Vendor_State],
	[Vendor].[Country] as [Vendor_Country]
from Erp.POHeader as POHeader
inner join Erp.PORel as PORel on 
	POHeader.Company = PORel.Company
And
	POHeader.PONum = PORel.PONum

inner join Erp.PartTran as PartTran on 
	PORel.Company = PartTran.Company
And
	PORel.PONum = PartTran.PONum
And
	PORel.POLine = PartTran.POLine
And
	PORel.PORelNum = PartTran.PORelNum
 and ( PartTran.TranQty > 0  )

inner join Erp.Part as Part on 
	PartTran.Company = Part.Company
And
	PartTran.PartNum = Part.PartNum

inner join Erp.Vendor as Vendor on 
	PartTran.Company = Vendor.Company
And
	PartTran.VendorNum = Vendor.VendorNum

 where (POHeader.OrderDate >= DATEADD (year, -1, GETDATE()))
 
 
 --query with multiple case statement, conditions and left outer join
 select 
	[Project].[ProjectID] as [Project_ProjectID],
	[ProjPhase].[PhaseID] as [ProjPhase_PhaseID],
	[ProjPhase].[Description] as [ProjPhase_Description],
	(case
 	when ProjPhase.ParentPhase = '08' then 'Phase 8'
 	when ProjPhase.ParentPhase = '09' then 'Phase 9'
   when ProjPhase.ParentPhase = '10' then 'Phase 10'
 	else 'Other'
 end) as [Calculated_ParentPhase],
	[ProjPhase].[DueDate] as [ProjPhase_DueDate],
	[ProjPhase].[DateComplete] as [ProjPhase_DateComplete],
	[ProjPhase].[PercentComplete] as [ProjPhase_PercentComplete],
	(case
 	when Project.SalesCatID = '10'  then 'Category 10'
 	when Project.SalesCatID = '2' then 'Category 2'
 	when Project.SalesCatID = '3' then 'Category 3'
 	when Project.SalesCatID = '++++' then '+++'
   else 'Other'
 end) as [Calculated_ProjectType],
	(case
 	when (ProjPhase.DateComplete = '' and ProjPhase.DueDate <= Constants.Today) then 'On-Time'
 	when (ProjPhase.DateComplete = '' and ProjPhase.DueDate > Constants.Today) then 'Late'
 	when (ProjPhase.DateComplete > ProjPhase.DueDate) then 'Late'
 	when (ProjPhase.DateComplete = ProjPhase.DueDate) then 'On-Time'
 	when (ProjPhase.DateComplete < ProjPhase.DueDate) then 'Early'
 	else 'Missing Information'
 end) as [Calculated_Status],
	(case
 	when ProjPhase.DateComplete <> '' then datediff(day, ProjPhase.DueDate, ProjPhase.DateComplete)
 	else ''
 end) as [Calculated_DaysLate],
	(concat(Project.ProjectID, ' ',ProjPhase.Description)) as [Calculated_ProjPhaseCombo]
from Erp.Project as Project
left outer join Erp.ProjPhase as ProjPhase on 
	ProjPhase.Company = Project.Company
And
	ProjPhase.ProjectID = Project.ProjectID
 and ( ProjPhase.ParentPhase in ('08', '09', '10')  )

 where (Project.PMPFReviewable_c = True  and Project.ActiveProject = True)
 
 
 --Query with inner join and conditions
 select 
	[PartBin].[Company] as [PartBin_Company],
	[PartPlant].[Plant] as [PartPlant_Plant],
	(@FromWarehouseCode) as [Calculated_FromWarehouseCode],
	(@FromBinNum) as [Calculated_FromBinNum],
	[PartBin].[PartNum] as [PartBin_PartNum],
	[PartBin].[OnhandQty] as [PartBin_OnhandQty],
	(@ToWarehouseCode) as [Calculated_ToWarehouseCode],
	(@ToBinNum) as [Calculated_ToBinNum],
	(@TranReference) as [Calculated_TranReference]
from Erp.PartBin as PartBin
inner join Erp.PartPlant as PartPlant on 
	PartBin.Company = PartPlant.Company
And
	PartBin.PartNum = PartPlant.PartNum

 where (PartBin.WarehouseCode = @FromWarehouseCode  and PartBin.BinNum = @FromBinNum)
 
 
 --query with inner joins, left outer joins, conditions, and group by, and order by
 select 
	[JobMtl].[PartNum] as [JobMtl_PartNum],
	[JobMtl].[Description] as [JobMtl_Description],
	[Part].[TypeCode] as [Part_TypeCode],
	[Part].[ClassID] as [Part_ClassID],
	[JobMtl].[BuyIt] as [JobMtl_BuyIt],
	[JobHead].[ContractID] as [JobHead_ContractID],
	[JobMtl].[LinkToContract] as [JobMtl_LinkToContract],
	[JobMtl].[Direct] as [JobMtl_Direct],
	(sum(JobMtl.RequiredQty)) as [Calculated_TotalExtQty],
	(sum(JobMtl.IssuedQty)) as [Calculated_TotalIssuedQty],
	[SubQuery2].[Calculated_TotalOnHandQty] as [Calculated_TotalOnHandQty],
	[SubQuery3].[Calculated_TotalOpenPOQty] as [Calculated_TotalOpenPOQty],
	(TotalExtQty - TotalIssuedQty) as [Calculated_TotalQtyShort]
from Erp.JobMtl as JobMtl
inner join Erp.JobHead as JobHead on 
	JobMtl.Company = JobHead.Company
And
	JobMtl.JobNum = JobHead.JobNum
 and ( JobHead.JobNum like @JobNum  and JobHead.JobCode = @JobCode  and JobHead.ProjectID = @ProjectID  and JobHead.ContractID = @PlanningContract  and JobHead.JobComplete = FALSE  )

inner join Erp.Part as Part on 
	Part.Company = JobMtl.Company
And
	Part.PartNum = JobMtl.PartNum

left outer join  (select 
	[PartBin].[PartNum] as [PartBin_PartNum],
	(sum(PartBin.OnhandQty)) as [Calculated_TotalOnHandQty]
from Erp.PartBin as PartBin
 where (PartBin.BinNum <> '+++++++')
group by [PartBin].[PartNum])  as SubQuery2 on 
	SubQuery2.PartBin_PartNum = JobMtl.PartNum

left outer join  (select 
	[PODetail1].[PartNum] as [PODetail1_PartNum],
	(sum(PODetail1.OrderQty)) as [Calculated_TotalOpenPOQty]
from Erp.PODetail as PODetail1
 where (PODetail1.OpenLine = TRUE)
group by [PODetail1].[PartNum])  as SubQuery3 on 
	JobMtl.PartNum = SubQuery3.PODetail1_PartNum

group by [JobMtl].[PartNum],
	[JobMtl].[Description],
	[Part].[TypeCode],
	[Part].[ClassID],
	[JobMtl].[BuyIt],
	[JobHead].[ContractID],
	[JobMtl].[LinkToContract],
	[JobMtl].[Direct],
	[SubQuery2].[Calculated_TotalOnHandQty],
	[SubQuery3].[Calculated_TotalOpenPOQty]
 order by  JobMtl.PartNum 
 
 
 --Query that includes subqueries, inner joins, 
 
 select 
	[JobHead].[JobNum] as [JobHead_JobNum],
	[JobAsmbl].[AssemblySeq] as [JobAsmbl_AssemblySeq],
	[JobAsmbl].[PartNum] as [JobAsmbl_PartNum],
	[JobAsmbl].[Description] as [JobAsmbl_Description]
from Erp.JobMtl as JobMtl
inner join Erp.JobHead as JobHead on 
	JobMtl.Company = JobHead.Company
And
	JobMtl.JobNum = JobHead.JobNum
 and ( JobHead.ProjectID like '+++++'  )

inner join Erp.JobAsmbl as JobAsmbl on 
	JobHead.Company = JobAsmbl.Company
And
	JobHead.JobNum = JobAsmbl.JobNum

inner join  (select 
	[PartBOM].[EndPartNum] as [PartBOM_EndPartNum],
	[PartBOM].[EndRevision] as [PartBOM_EndRevision],
	[PartBOM].[MtlPartNum] as [PartBOM_MtlPartNum],
	[PartBOM].[MtlRevision] as [PartBOM_MtlRevision],
	[PartBOM].[BOMType] as [PartBOM_BOMType],
	[PartBOM].[IndMtlPartNum] as [PartBOM_IndMtlPartNum]
from Erp.PartBOM as PartBOM
inner join  (select 
	[PartPlant].[Company] as [PartPlant_Company],
	[PartPlant].[PartNum] as [PartPlant_PartNum],
	[PartRev].[RevisionNum] as [PartRev_RevisionNum]
from Erp.PartPlant as PartPlant
inner join Erp.PartRev as PartRev on 
	PartPlant.Company = PartRev.Company
And
	PartPlant.PartNum = PartRev.PartNum
 and ( PartRev.Approved = True  )

 where (PartPlant.PhantomBOM = True))  as SubQuery2 on 
	PartBOM.EndPartNum = SubQuery2.PartPlant_PartNum
And
	PartBOM.EndRevision = SubQuery2.PartRev_RevisionNum)  as SubQuery3 on 
	JobHead.PartNum = SubQuery3.PartBOM_EndPartNum
	
	
--Query involving calculated fields, inner joins, and case statement
select 
	[JobMtl].[Company] as [JobMtl_Company],
	[JobHead].[ProjectID] as [JobHead_ProjectID],
	[JobHead].[JobCode] as [JobHead_JobCode],
	[JobMtl].[PartNum] as [JobMtl_PartNum],
	[JobMtl].[Description] as [JobMtl_Description],
	[JobMtl].[JobNum] as [JobMtl_JobNum],
	[JobMtl].[AssemblySeq] as [JobMtl_AssemblySeq],
	[JobMtl].[MtlSeq] as [JobMtl_MtlSeq],
	[JobMtl].[RequiredQty] as [JobMtl_RequiredQty],
	[JobMtl].[IssuedQty] as [JobMtl_IssuedQty],
	[PartBin].[OnhandQty] as [PartBin_OnhandQty],
	((case when PartBin.OnhandQty >  ( JobMtl.RequiredQty - JobMtl.IssuedQty )  then ( JobMtl.RequiredQty - JobMtl.IssuedQty )   else  PartBin.OnhandQty end)) as [Calculated_QtyToIssue],
	[PartBin].[WarehouseCode] as [PartBin_WarehouseCode],
	[PartBin].[BinNum] as [PartBin_BinNum],
	[PartCost].[AvgMaterialCost] as [PartCost_AvgMaterialCost],
	(PartCost.AvgMaterialCost * QtyToIssue) as [Calculated_IssuedValue]
from Erp.JobMtl as JobMtl
inner join Erp.PartBin as PartBin on 
	JobMtl.Company = PartBin.Company
And
	JobMtl.PartNum = PartBin.PartNum
 and ( PartBin.WarehouseCode = @Warehouse  and PartBin.BinNum like @WarehouseBin  )

inner join Erp.JobHead as JobHead on 
	JobMtl.Company = JobHead.Company
And
	JobMtl.JobNum = JobHead.JobNum
 and ( JobHead.JobComplete = FALSE  and JobHead.JobClosed = FALSE  and JobHead.ProjectID = @ProjectID  and JobHead.JobCode = @JobCode  and JobHead.JobReleased = True  )

inner join Erp.PartCost as PartCost on 
	PartCost.Company = JobMtl.Company
And
	PartCost.PartNum = JobMtl.PartNum

 where (JobMtl.IssuedComplete = FALSE  and JobMtl.RequiredQty > 0  and not JobMtl.RequiredQty <= JobMtl.IssuedQty  and JobMtl.PartNum like @PartNum)
 order by  IssuedValue Desc
 
 
 --query that includes inner joins and group by
  select 
	[JobHead].[JobNum] as [JobHead_JobNum],
	[JobHead].[JobComplete] as [JobHead_JobComplete],
	[JobHead].[JobClosed] as [JobHead_JobClosed],
	[JobHead].[ProdQty] as [JobHead_ProdQty],
	[JobHead].[QtyCompleted] as [JobHead_QtyCompleted],
	[PartTran].[TranType] as [PartTran_TranType],
	(sum(PartTran.TranQty  )) as [Calculated_TranQtyCons]
from Erp.JobHead as JobHead
inner join Erp.PartTran as PartTran on 
	JobHead.Company = PartTran.Company
And
	JobHead.JobNum = PartTran.JobNum
And
	JobHead.PartNum = PartTran.PartNum

 where (JobHead.Candidate = True  and JobHead.JobClosed = False  and JobHead.ProdQty = JobHead.QtyCompleted)
group by [JobHead].[JobNum],
	[JobHead].[JobComplete],
	[JobHead].[JobClosed],
	[JobHead].[ProdQty],
	[JobHead].[QtyCompleted],
	[PartTran].[TranType]

	
--query that includes user parameters, calculations, inner joins, group by, distinct and results in a loadable results
select distinct
	[JobMtl].[Company] as [JobMtl_Company],
	[JobMtl].[JobNum] as [JobMtl_JobNum],
	[JobMtl].[AssemblySeq] as [JobMtl_AssemblySeq],
	[JobMtl].[MtlSeq] as [JobMtl_MtlSeq],
	(@ToWarehouseCode) as [Calculated_ToWarehouseCode],
	(@ToBinNum) as [Calculated_ToBinNum],
	(@TranReference) as [Calculated_TranReference],
	(-(JobMtl.RequiredQty - SubQuery2.Calculated_TranQty3)) as [Calculated_TranQty]
from Erp.JobMtl as JobMtl
inner join Erp.JobHead as JobHead on 
	JobHead.Company = JobMtl.Company
And
	JobHead.JobNum = JobMtl.JobNum
 and ( JobHead.ProjectID = @ProjectID  and JobHead.JobNum = @JobNum  and JobHead.JobCode like @JobCode  and JobHead.JobComplete = false  and JobHead.JobClosed = false  )

inner join Erp.JobAsmbl as JobAsmbl on 
	JobMtl.Company = JobAsmbl.Company
And
	JobMtl.JobNum = JobAsmbl.JobNum
And
	JobMtl.AssemblySeq = JobAsmbl.AssemblySeq

inner join Erp.Part as Part on 
	Part.Company = JobMtl.Company
And
	Part.PartNum = JobMtl.PartNum
 and ( Part.InActive = False  )

inner join  (select distinct
	[PartTran1].[JobNum] as [PartTran1_JobNum],
	[PartTran1].[AssemblySeq] as [PartTran1_AssemblySeq],
	[PartTran1].[JobSeq] as [PartTran1_JobSeq],
	(sum(PartTran1.ActTranQty)) as [Calculated_TranQty3]
from Erp.PartTran as PartTran1
inner join Erp.JobHead as JobHead1 on 
	PartTran1.Company = JobHead1.Company
And
	PartTran1.JobNum = JobHead1.JobNum
 and ( JobHead1.JobNum = @JobNum  or JobHead1.ProjectID = @ProjectID  or JobHead1.JobCode like @JobCode  )

 where (PartTran1.TranClass = 'I')
group by [PartTran1].[JobNum],
	[PartTran1].[AssemblySeq],
	[PartTran1].[JobSeq])  as SubQuery2 on 
	JobMtl.JobNum = SubQuery2.PartTran1_JobNum
And
	JobMtl.AssemblySeq = SubQuery2.PartTran1_AssemblySeq
And
	JobMtl.MtlSeq = SubQuery2.PartTran1_JobSeq

 where (-(JobMtl.RequiredQty - SubQuery2.Calculated_TranQty3)) > 0
 
 
 --query includes inner joins, left outer joins, case statements
 select distinct
	[JobAsmbl].[PartNum] as [JobAsmbl_PartNum],
	[JobAsmbl].[RevisionNum] as [JobAsmbl_RevisionNum],
	[JobAsmbl].[Description] as [JobAsmbl_Description],
	((case when ECOOpr.OprSeq >0 then 1 else 0 end)) as [Calculated_HasBOO],
	((case when JobOper.OprSeq > 0 then 1 else 0 end)) as [Calculated_HasJobBOO],
	[JobHead].[JobNum] as [JobHead_JobNum],
	[JobAsmbl].[AssemblySeq] as [JobAsmbl_AssemblySeq],
	[PartPlant].[MfgLeadTimeMnl] as [PartPlant_MfgLeadTimeMnl],
	[PartPlant].[TotMfgLeadTimeSys] as [PartPlant_TotMfgLeadTimeSys],
	[PartPlant].[LvlMfgLeadTimeSys] as [PartPlant_LvlMfgLeadTimeSys],
	[PartPlant].[MfgLeadTimeCalcDate] as [PartPlant_MfgLeadTimeCalcDate],
	[PartPlant].[TotMfgLeadTimeMnl] as [PartPlant_TotMfgLeadTimeMnl],
	[PartPlant].[LvlMfgLeadTimeMnl] as [PartPlant_LvlMfgLeadTimeMnl],
	[PartPlant].[MfgLeadTimeMnlDate] as [PartPlant_MfgLeadTimeMnlDate]
from Erp.JobAsmbl as JobAsmbl
inner join Erp.ECOMtl as ECOMtl on 
	JobAsmbl.Company = ECOMtl.Company
And
	JobAsmbl.PartNum = ECOMtl.PartNum
And
	JobAsmbl.RevisionNum = ECOMtl.RevisionNum

inner join Erp.ECORev as ECORev on 
	ECOMtl.Company = ECORev.Company
And
	ECOMtl.GroupID = ECORev.GroupID
And
	ECOMtl.PartNum = ECORev.PartNum
And
	ECOMtl.RevisionNum = ECORev.RevisionNum
And
	ECOMtl.AltMethod = ECORev.AltMethod
 and ( ECORev.Approved = True  )

left outer join Erp.ECOOpr as ECOOpr on 
	ECORev.Company = ECOOpr.Company
And
	ECORev.GroupID = ECOOpr.GroupID
And
	ECORev.PartNum = ECOOpr.PartNum
And
	ECORev.RevisionNum = ECOOpr.RevisionNum
And
	ECORev.AltMethod = ECOOpr.AltMethod

inner join Erp.JobHead as JobHead on 
	JobAsmbl.Company = JobHead.Company
And
	JobAsmbl.JobNum = JobHead.JobNum
 and ( JobHead.ProjectID like '++++++'  )

left outer join Erp.JobOper as JobOper on 
	JobAsmbl.Company = JobOper.Company
And
	JobAsmbl.JobNum = JobOper.JobNum
And
	JobAsmbl.AssemblySeq = JobOper.AssemblySeq

inner join Erp.PartPlant as PartPlant on 
	JobAsmbl.Company = PartPlant.Company
And
	JobAsmbl.PartNum = PartPlant.PartNum
	

 
 