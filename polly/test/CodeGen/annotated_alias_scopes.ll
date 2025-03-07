; RUN: opt %loadNPMPolly -passes=polly-codegen -S < %s | FileCheck %s --check-prefix=SCOPES
;
; Check that we create alias scopes that indicate the accesses to A, B and C cannot alias in any way.
;
; SCOPES-LABEL: polly.stmt.for.body:
; SCOPES:      %[[BIdx:[._a-zA-Z0-9]*]] = getelementptr{{.*}} ptr %B, i64 %{{.*}}
; SCOPES:      load i32, ptr %[[BIdx]], align 4, !alias.scope !2, !noalias !5
; SCOPES:      %[[CIdx:[._a-zA-Z0-9]*]] = getelementptr{{.*}} ptr %C, i64 %{{.*}}
; SCOPES:      load float, ptr %[[CIdx]], align 4, !alias.scope !8, !noalias !9
; SCOPES:      %[[AIdx:[._a-zA-Z0-9]*]] = getelementptr{{.*}} ptr %A, i64 %{{.*}}
; SCOPES:      store i32 %{{[._a-zA-Z0-9]*}}, ptr %[[AIdx]], align 4, !alias.scope !10, !noalias !11
;
; SCOPES: !0 = distinct !{!0, !1}
; SCOPES: !1 = !{!"llvm.loop.vectorize.enable", i32 0}
; SCOPES: !2 = !{!3}
; SCOPES: !3 = distinct !{!3, !4, !"polly.alias.scope.MemRef_B"}
; SCOPES: !4 = distinct !{!4, !"polly.alias.scope.domain"}
; SCOPES: !5 = !{!6, !7}
; SCOPES: !6 = distinct !{!6, !4, !"polly.alias.scope.MemRef_C"}
; SCOPES: !7 = distinct !{!7, !4, !"polly.alias.scope.MemRef_A"}
; SCOPES: !8 = !{!6}
; SCOPES: !9 = !{!3, !7}
; SCOPES: !10 = !{!7}
; SCOPES: !11 = !{!3, !6}
;
;    void jd(int *A, int *B, float *C) {
;      for (int i = 0; i < 1024; i++)
;        A[i] = B[i] + C[i];
;    }
;
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

define void @jd(ptr %A, ptr %B, ptr %C) {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.inc ], [ 0, %entry ]
  %exitcond = icmp ne i64 %indvars.iv, 1024
  br i1 %exitcond, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds i32, ptr %B, i64 %indvars.iv
  %tmp = load i32, ptr %arrayidx, align 4
  %conv = sitofp i32 %tmp to float
  %arrayidx2 = getelementptr inbounds float, ptr %C, i64 %indvars.iv
  %tmp1 = load float, ptr %arrayidx2, align 4
  %add = fadd fast float %conv, %tmp1
  %conv3 = fptosi float %add to i32
  %arrayidx5 = getelementptr inbounds i32, ptr %A, i64 %indvars.iv
  store i32 %conv3, ptr %arrayidx5, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}
