%% Add path
addpath(genpath('MM_testfunctions/'));
addpath(genpath('Indicator_calculation/'));
clear all
clc
%   rand('state',sum(100*clock));
global fname
N_function=1;% number of test function
popsize=1000;
runtimes=1;
Max_evaluation=80000;
Max_Gen=fix(Max_evaluation/popsize);
tic
% Note: It may take a long time to run all 11 test functions and with
% population size 800 and generation 100. You can change N_function to 1,
%  popsize to 100, Max_evaluation to 1000, to see how the MO_Ring_PSO_SCD
%  works.
for i=1:1
switch i
    case 1
        fname='MMF1';  % function name
        n_obj=2;       % the dimensions of the decision space
        n_var=2;       % the dimensions of the objective space
        xl=[1 -1];     % the low bounds of the decision variables
        xu=[3 1];      % the up bounds of the decision variables
        repoint=[2,2]; % reference point used to calculate the Hypervolume
        load('MMF1truePSPF.mat');
        load('th.mat');
        Th=th{1,i};
    case 2
        fname='MMF2';
        n_obj=2;
        n_var=2;
        xl=[0 0];
        xu=[1 2];
        repoint=[2,2];
        load('MMF2truePSPF.mat');
        load('th.mat');
        Th=th{1,i};
    case 3
        fname='MMF3';
        n_obj=2;
        n_var=2;
        xl=[0 0];                                                                                                              
        xu=[1 1.5];
        repoint=[2,2];
        load('MMF3truePSPF.mat');
         load('th.mat');
        Th=th{1,i};
    case 4
        fname='MMF4';
        n_obj=2;
        n_var=2;
        xl=[-1 0];
        xu=[1 2];
        repoint=[2,2];
        load('MMF4truePSPF.mat');
         load('th.mat');
        Th=th{1,i};
    case 5
        fname='MMF5';
        n_obj=2;
        n_var=2;
        xl=[1 -1];
        xu=[3 3];
        repoint=[2,2];
        load('MMF5truePSPF.mat');
         load('th.mat');
        Th=th{1,i};
    case 6
        fname='MMF6';
        n_obj=2;
        n_var=2;
        xl=[1 -1];
        xu=[3 2];
        repoint=[2,2];
        load('MMF6truePSPF.mat');
         load('th.mat');
        Th=th{1,i};
    case 7
        fname='MMF7';
        n_obj=2;
        n_var=2;
        xl=[1 -1];
        xu=[3 1];
        repoint=[2,2];
        load('MMF7truePSPF.mat');
         load('th.mat');
        Th=th{1,i};
    case 8
        fname='MMF8';
        n_obj=2;
        n_var=2;
        xl=[-pi 0];
        xu=[pi 9];
        repoint=[2,2];
        load('MMF8truePSPF.mat');
         load('th.mat');
        Th=th{1,i};
    case 9
        fname='SYM_PART_simple';
        n_obj=2;
        n_var=2;
        xl=[-20 -20];
        xu=[20 20];
        repoint=[2,2];
        load('SYM_PART_simple_turePSPF.mat');
         load('th.mat');
        Th=th{1,i};
    case 10
        fname='SYM_PART_rotated';
        n_obj=2;
        n_var=2;
        xl=[-20 -20];
        xu=[20 20];
        repoint=[2,2];
        load('SYM_PART_rotatedtruePSPF.mat');
         load('th.mat');
        Th=th{1,i};
    case 11
        fname='Omni_test';
        n_obj=2;
        n_var=3;
        xl=[0 0 0];
        xu=[6 6 6];
        repoint=[5,5];
        load('Omni_testtruePSPF.mat');
         load('th.mat');
        Th=th{1,i};
        
end

fprintf('Running test function: %s \n', fname );
for j=1:runtimes
    fprintf(2,' runtimes= %u/%u\n',j,runtimes)
    %% Search the PSs using MO_Ring_PSO_SCD
    [count,ps,pf]=MMGPE(Th,fname,xl,xu,n_obj,popsize,Max_Gen);
    %% Indicators
    hyp=Hypervolume_calculation(pf,repoint);
    IGDx=IGD_calculation(ps,PS);
    CR=CR_calculation(ps,PS);
    PSP=CR/IGDx;% Eq. (8) in the paper
    hv(1,j)=hyp;
    IGDX(1,j)=IGDx;
    cR(1,j)=CR;
    psp(1,j)=PSP;
    pF(j)={pf};
    pS(j)={ps};
    
end
Mean(i)=mean(hv);
Std(i)=std(hv);
Mean1(i)=mean(psp);
Std1(i)=std(psp);
ccR(i)={cR};
hhv(i)={hv};
IIGDX(i)={IGDX};
ppsp(i)={psp};
ppF(i)={pF};
ppS(i)={pS};

%% Plot figure
%% Plot figure
% figure(i)
% plot(ps(:,1),ps(:,2),'o');
% % hold on;
% figure(i+11)
% plot(pf(:,1),pf(:,2),'r+');
% legend 'Obtained PS' 'True PS'
% title (fname);
figure
plot(ps(:,1),ps(:,2),'o');
hold on;
plot(PS(:,1),PS(:,2),'r+');
legend 'Obtained PS' 'True PS'
title (fname);
  end
  toc
  save 20200312.mat Mean Std Mean1 Std1 ccR hhv ppF ppS hhv IIGDX ppsp
 


