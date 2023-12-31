function [count,ps,pf]=MMGPE(Th,func_name,VRmin,VRmax,n_obj,Particle_Number,Max_Gen)

% MO_Ring_PSO_SCD: A multi-objective particle swarm optimization using ring topology for solving multimodal multi-objective optimization problems
% Dimension: n_var --- dimensions of decision space
%            n_obj --- dimensions of objective space
%% Input:
%                      Dimension                    Description
%      func_name       1 x length function name     the name of test function
%      VRmin           1 x n_var                    low bound of decision variable
%      VRmax           1 x n_var                    up bound of decision variable
%      n_obj           1 x 1                        dimensions of objective space
%      Particle_Number 1 x 1                        population size
%      Max_Gen         1 x 1                        maximum  generations

%% Output:
%                     Description
%      ps             Pareto set
%      pf             Pareto front
%%  Reference and Contact
% Reference: [1]Caitong Yue, Boyang Qu and Jing Liang, "A Multi-objective Particle Swarm Optimizer Using Ring Topology for Solving Multimodal Multi-objective Problems",  IEEE Transactions on Evolutionary Computation, 2017, DOI 10.1109/TEVC.2017.2754271.
%            [2]Jing Liang, Caitong Yue, and Boyang Qu, “ Multimodal multi-objective optimization: A preliminary study”, IEEE Congress on Evolutionary Computation 2016, pp. 2454-2461, 2016.
% Contact: For any questions, please feel free to send email to zzuyuecaitong@163.com.

%% Initialize parameters
n_var=size(VRmin,2);               %Obtain the dimensions of decision space
Max_FES=Max_Gen*Particle_Number;   %Maximum fitness evaluations
n_PBA=5;                           %Maximum size of PBA. The algorithm will perform better without the size limit of PBA. But it will time consuming.
n_NBA=3*n_PBA;                     %Maximum size of NBA
cc=[2.05 2.05];                    %Acceleration constants
iwt=0.7298;                        %Inertia weight
count=zeros(500,3);
%% Initialize particles' positions and velocities
mv=0.5*(VRmax-VRmin);
VRmin=repmat(VRmin,Particle_Number,1);
VRmax=repmat(VRmax,Particle_Number,1);
Vmin=repmat(-mv,Particle_Number,1);
Vmax=-Vmin;
pos=VRmin+(VRmax-VRmin).*rand(Particle_Number,n_var); %initialize the positions of the particles
vel=Vmin+2.*Vmax.*rand(Particle_Number,n_var);        %initialize the velocities of the particles
Vrmin=(VRmin+abs(VRmin));
Vrmax=(VRmax+abs(VRmin));
Pos=pos+abs(VRmin);
OriginX(1)={Pos};                       % 存储第一代
%% Evaluate the population
fitness=zeros(Particle_Number,n_obj);
for i=1:Particle_Number
    fitness(i,:)=feval(func_name,pos(i,:));
end
fitcount=Particle_Number;            % count the number of fitness evaluations
particle=[pos,fitness];              %put positions and velocities in one matrix
%% Initialize personal best archive PBA and Neighborhood best archive NBA
row_of_cell=ones(1,Particle_Number); % the number of row in each cell
col_of_cell=size(particle,2);        % the number of column in each cell
PBA=mat2cell(particle,row_of_cell,col_of_cell);
NBA=PBA;

for i=2:3
    %% Update NBA
    for j=1:Particle_Number
        % Ring topology.  Particles exchange information with its closed neighbors
        if j==1
            tempNBA=PBA{Particle_Number,:};
            tempNBA=[tempNBA;PBA{1,:}];
            tempNBA=[tempNBA;PBA{2,:}];
        elseif j==Particle_Number
            tempNBA=PBA{Particle_Number-1,:};
            tempNBA=[tempNBA;PBA{Particle_Number,:}];
            tempNBA=[tempNBA;PBA{1,:}];
        else
            tempNBA=PBA{j-1,:};
            tempNBA=[tempNBA;PBA{j,:}];
            tempNBA=[tempNBA;PBA{j+1,:}];
        end
        NBA_j=NBA{j,1};
        tempNBA=[tempNBA;NBA_j];
        tempNBA=non_domination_scd_sort(tempNBA(:,1:n_var+n_obj), n_obj, n_var);
        % Optional operation. Limit the size of NBA to save time.
        if size(tempNBA,1)>n_NBA
            NBA{j,1}=tempNBA(1:n_NBA,:);
        else
            NBA{j,1}=tempNBA;
        end
    end
    for k=1:Particle_Number
        % Choose the first particle in PBA_k as pbest
        PBA_k=PBA{k,1};       %PBA_k contains the history positions of particle_k
        pbest=PBA_k(1,:);     %Choose the first one
        % Choose the first particle in NBA_k as nbest
        NBA_k=NBA{k,:};      %NBA_k contains the history positions of particle_k's neighborhood
        nbest=NBA_k(1,:);
        % Update velocities according to Eq.(5)
        vel(k,:)=iwt.*vel(k,:)+cc(1).*rand(1,n_var).*(pbest(1,1:n_var)-pos(k,:))+cc(2).*rand(1,n_var).*(nbest(1,1:n_var)-pos(k,:));
        % Make sure that velocities are in the setting bounds.
        vel(k,:)=(vel(k,:)>mv).*mv+(vel(k,:)<=mv).*vel(k,:);
        vel(k,:)=(vel(k,:)<(-mv)).*(-mv)+(vel(k,:)>=(-mv)).*vel(k,:);
        % Update positions according to Eq.(4)
        pos(k,:)=pos(k,:)+vel(k,:);
        % Make sure that positions are in the setting bounds.
        pos(k,:)=((pos(k,:)>=VRmin(1,:))&(pos(k,:)<=VRmax(1,:))).*pos(k,:)...
            +(pos(k,:)<VRmin(1,:)).*(VRmin(1,:)+0.25.*(VRmax(1,:)-VRmin(1,:)).*rand(1,n_var))+(pos(k,:)>VRmax(1,:)).*(VRmax(1,:)-0.25.*(VRmax(1,:)-VRmin(1,:)).*rand(1,n_var));
        % Evaluate the population
        fitness(k,:)=feval(func_name,pos(k,1:n_var));
        fitcount=fitcount+1;
        particle(k,1:n_var+n_obj)=[pos(k,:),fitness(k,:)];
        %% Update PBA
        PBA_k=[PBA_k(:,1:n_var+n_obj);particle(k,:)];
        PBA_k = non_domination_scd_sort(PBA_k(:,1:n_var+n_obj), n_obj, n_var);
        % Optional operation. Limit the size of PBA to save time.
        if size(PBA_k,1)>n_PBA
            PBA{k,1}=PBA_k(1:n_PBA,:);
        else
            PBA{k,1}=PBA_k;
        end
        PBA_k=PBA{k,1};
        C(k,:)=PBA_k(1,:);
    end
       D= C(:,1:n_var);
       Pos=D+abs(VRmin);
       OriginX(i)={Pos};
end

for i=4:(Max_Gen)
    for j=1:Particle_Number
        % Ring topology.  Particles exchange information with its closed neighbors
        if j==1
            tempNBA=PBA{Particle_Number,:};
            tempNBA=[tempNBA;PBA{1,:}];
            tempNBA=[tempNBA;PBA{2,:}];
        elseif j==Particle_Number
            tempNBA=PBA{Particle_Number-1,:};
            tempNBA=[tempNBA;PBA{Particle_Number,:}];
            tempNBA=[tempNBA;PBA{1,:}];
        else
            tempNBA=PBA{j-1,:};
            tempNBA=[tempNBA;PBA{j,:}];
            tempNBA=[tempNBA;PBA{j+1,:}];
        end
        NBA_j=NBA{j,1};
        tempNBA=[tempNBA;NBA_j];
        tempNBA=non_domination_scd_sort(tempNBA(:,1:n_var+n_obj), n_obj, n_var);
        % Optional operation. Limit the size of NBA to save time.
        if size(tempNBA,1)>n_NBA
            NBA{j,1}=tempNBA(1:n_NBA,:);
        else
            NBA{j,1}=tempNBA;
        end
    end
    
    t=0.01-(0.05/(Max_Gen))*(i-(Max_Gen));
    aa=randperm(Particle_Number);
    bb=randperm(Particle_Number);
    cc=randperm(Particle_Number);
    for k=1:Particle_Number
        NBA_ii=NBA{k,:};      %NBA_k contains the history positions of particle_k's neighborhood
        nbest=NBA_ii(1,:);
        Nbest=nbest(1,1:n_var)+abs(VRmin(k,:));
        for jj=1: n_var
            X0=[OriginX{1,1}(aa(k),jj),OriginX{1,2}(bb(k),jj),OriginX{1,3}(cc(k),jj)];
            if abs(max(X0)-min(X0))<Th(jj)
                count(i,1)=count(i,1)+1;
                  X0(3)= Nbest(jj);
                Pos(k,jj)=X0(3)+t*2*abs(max(X0)-min(X0))*(rand-0.5);
            elseif (max(X0)~=min(X0))&&(abs(X0(1)-X0(2))<Th(jj)||abs(X0(1)-X0(3))<Th(jj)||abs(X0(2)-X0(3))<Th(jj))
               count(i,2)=count(i,2)+1;
%                  X0(3)= Nbest(jj);
                Pos(k,jj)=(4*X0(3)+X0(2)-2*X0(1))./3;
            else
                count(i,3)=count(i,3)+1; 
                a=2*(X0(2)-X0(3))/(X0(2)+X0(3));
                b=2*(X0(1)*X0(2)+X0(2)^2-X0(1)*X0(3))/(X0(2)+X0(3));
%               Pos(k,jj)=(1-exp(a))*(X0(1)-b/a)*exp(-(3*a));
               lamda=0.1;
              Pos(k,jj)=((1-exp(a*(lamda)))*(X0(1)-b/a)*exp(-a*(lamda+2)))/lamda;
                %预测后续数据
%                 F=[];
%                 for tt=1:4
%                     F(tt)=(X0(1)-b/a)/exp(a*(tt-1))+b/a;
%                 end
%                 G=[];
%                 G(1)=X0(1);
%                 for tt=2:4 %只推测后1个数据，可以从此修改
%                     G(tt)=F(tt)-F(tt-1);  %得到预测出来的数据
%                 end
%                 Pos(k,jj)=G(4);
            end
            % 对种群Pos超出范围的重新赋值
            if  Pos(k,jj)< Vrmin(k,jj)|Pos(k,jj)> Vrmax(k,jj)
                Pos(k,jj)=Vrmin(k,jj)+( Vrmax(k,jj)- Vrmin(k,jj))*rand;
            end
        end
        
        %% Make sure that positions are in the setting bounds.
        Pos(k,:)=((Pos(k,:)>=Vrmin(1,:))&(Pos(k,:)<=Vrmax(1,:))).*Pos(k,:)...
            +(Pos(k,:)<Vrmin(1,:)).*(Vrmin(1,:)+0.25.*(Vrmax(1,:)-Vrmin(1,:)).*rand(1,n_var))+(Pos(k,:)>Vrmax(1,:)).*(Vrmax(1,:)-0.25.*(Vrmax(1,:)-Vrmin(1,:)).*rand(1,n_var));
%        %%还原预测粒子的位置
        pos(k,:)=Pos(k,:)-abs(VRmin(k,:));
        %% Make sure that positions are in the setting bounds.
        pos(k,:)=((pos(k,:)>=VRmin(1,:))&(pos(k,:)<=VRmax(1,:))).*pos(k,:)...
            +(pos(k,:)<VRmin(1,:)).*(VRmin(1,:)+0.25.*(VRmax(1,:)-VRmin(1,:)).*rand(1,n_var))+(pos(k,:)>VRmax(1,:)).*(VRmax(1,:)-0.25.*(VRmax(1,:)-VRmin(1,:)).*rand(1,n_var));
        %% Evaluate the population
        fitness(k,:)=feval(func_name,pos(k,1:n_var));
        fitcount=fitcount+1;
        particle(k,1:n_var+n_obj)=[pos(k,:),fitness(k,:)];
        %% Update PBA
        PBA_k=PBA{k,1};
        PBA_k=[PBA_k(:,1:n_var+n_obj);particle(k,:)];
        PBA_k = non_domination_scd_sort(PBA_k(:,1:n_var+n_obj), n_obj, n_var);
        % Optional operation. Limit the size of PBA to save time.
        if size(PBA_k,1)>n_PBA
            PBA{k,1}=PBA_k(1:n_PBA,:);
        else
            PBA{k,1}=PBA_k;
        end
        PBA_k=PBA{k,1};
        C(k,:) = PBA_k(1,:);
    end
       D= C(:,1:n_var);
       Pos=D+abs(VRmin);
       OriginX(1,4)={Pos};
       OriginX=OriginX(2:4);
    if fitcount>Max_FES
        break;
    end
end
%% Output ps and pf
tempEXA=cell2mat(NBA);
tempEXA=non_domination_scd_sort(tempEXA(:,1:n_var+n_obj), n_obj, n_var);
if size(tempEXA,1)>Particle_Number
    EXA=tempEXA(1:Particle_Number,:);
else
    EXA=tempEXA;
end
% p_index=randperm(size(EXA,1),800); 
% EXA=EXA(p_index,:);
% tempEXA=non_domination_scd_sort(EXA(:,1:n_var+n_obj), n_obj, n_var);
EXA=tempEXA(1:800,:);
tempindex=find(EXA(:,n_var+n_obj+1)==1);% Find the index of the first rank particles
ps=EXA(tempindex,1:n_var);
pf=EXA(tempindex,n_var+1:n_var+n_obj);
end



function f = non_domination_scd_sort(x, n_obj, n_var)
% non_domination_scd_sort:  sort the population according to non-dominated relationship and special crowding distance
%% Input：
%                      Dimension                      Description
%      x               num_particle x n_var+n_obj     population to be sorted     
%      n_obj           1 x 1                          dimensions of objective space
%      n_var           1 x 1                          dimensions of decision space

%% Output:
%              Dimension                                  Description
%      f       N_particle x (n_var+n_obj+4)               Sorted population  
%    in f      the (n_var+n_obj+1)_th column stores the front number
%              the (n_var+n_obj+2)_th column stores the special crowding distance   
%              the (n_var+n_obj+3)_th column stores the crowding distance in decision space
%              the (n_var+n_obj+4)_th column stores the crowding distance in objective space


    [N_particle, ~] = size(x);% Obtain the number of particles

% Initialize the front number to 1.
    front = 1;

% There is nothing to this assignment, used only to manipulate easily in
% MATLAB.
    F(front).f = [];
    individual = [];

%% Non-Dominated sort. 

    for i = 1 : N_particle
        % Number of individuals that dominate this individual
        individual(i).n = 0; 
        % Individuals which this individual dominate
        individual(i).p = [];
        for j = 1 : N_particle
            dom_less = 0;
            dom_equal = 0;
            dom_more = 0;
            for k = 1 : n_obj
                if (x(i,n_var + k) < x(j,n_var + k))
                    dom_less = dom_less + 1;
                elseif (x(i,n_var + k) == x(j,n_var + k))  
                    dom_equal = dom_equal + 1;
                else
                    dom_more = dom_more + 1;
                end
            end
            if dom_less == 0 && dom_equal ~= n_obj
                individual(i).n = individual(i).n + 1;
            elseif dom_more == 0 && dom_equal ~= n_obj
                individual(i).p = [individual(i).p j];
            end
        end   
        if individual(i).n == 0
            x(i,n_obj + n_var + 1) = 1;
            F(front).f = [F(front).f i];
        end
    end
% Find the subsequent fronts
    while ~isempty(F(front).f)
       Q = [];
       for i = 1 : length(F(front).f)
           if ~isempty(individual(F(front).f(i)).p)
                for j = 1 : length(individual(F(front).f(i)).p)
                    individual(individual(F(front).f(i)).p(j)).n = ...
                        individual(individual(F(front).f(i)).p(j)).n - 1;
                    if individual(individual(F(front).f(i)).p(j)).n == 0
                        x(individual(F(front).f(i)).p(j),n_obj + n_var + 1) = ...
                            front + 1;
                        Q = [Q individual(F(front).f(i)).p(j)];
                    end
               end
           end
       end
       front =  front + 1;
       F(front).f = Q;
    end
% Sort the population according to the front number
    [~,index_of_fronts] = sort(x(:,n_obj + n_var + 1));
    for i = 1 : length(index_of_fronts)
        sorted_based_on_front(i,:) = x(index_of_fronts(i),:);
    end
    current_index = 0;

%% SCD. Special Crowding Distance

    for front = 1 : (length(F) - 1)
  
        crowd_dist_obj = 0;
        y = [];
        previous_index = current_index + 1;
        for i = 1 : length(F(front).f)
            y(i,:) = sorted_based_on_front(current_index + i,:);%put the front_th rank into y
        end
        current_index = current_index + i;
   % Sort each individual based on the objective
        sorted_based_on_objective = [];
        for i = 1 : n_obj+n_var
            [sorted_based_on_objective, index_of_objectives] = ...
                sort(y(:,i));
            sorted_based_on_objective = [];
            for j = 1 : length(index_of_objectives)
                sorted_based_on_objective(j,:) = y(index_of_objectives(j),:);
            end
            f_max = ...
                sorted_based_on_objective(length(index_of_objectives), i);
            f_min = sorted_based_on_objective(1,  i);

            if length(index_of_objectives)==1
                y(index_of_objectives(1),n_obj + n_var + 1 + i) = 1;  %If there is only one point in current front
            elseif i>n_var
                % deal with boundary points in objective space
                % In minimization problem, set the largest distance to the low boundary points and the smallest distance to the up boundary points
                y(index_of_objectives(1),n_obj + n_var + 1 + i) = 1;
                y(index_of_objectives(length(index_of_objectives)),n_obj + n_var + 1 + i)=0;
            else
                % deal with boundary points in decision space
                % twice the distance between the boundary points and its nearest neibohood 
                 y(index_of_objectives(length(index_of_objectives)),n_obj + n_var + 1 + i)...
                    = 2*(sorted_based_on_objective(length(index_of_objectives), i)-...
                sorted_based_on_objective(length(index_of_objectives) -1, i))/(f_max - f_min);
                 y(index_of_objectives(1),n_obj + n_var + 1 + i)=2*(sorted_based_on_objective(2, i)-...
                sorted_based_on_objective(1, i))/(f_max - f_min);
            end
             for j = 2 : length(index_of_objectives) - 1
                next_obj  = sorted_based_on_objective(j + 1, i);
                previous_obj  = sorted_based_on_objective(j - 1,i);
                if (f_max - f_min == 0)
                    y(index_of_objectives(j),n_obj + n_var + 1 + i) = 1;
                else
                    y(index_of_objectives(j),n_obj + n_var + 1 + i) = ...
                         (next_obj - previous_obj)/(f_max - f_min);
                end
             end
        end
    %% Calculate distance in decision space
        crowd_dist_var = [];
        crowd_dist_var(:,1) = zeros(length(F(front).f),1);
        for i = 1 : n_var
            crowd_dist_var(:,1) = crowd_dist_var(:,1) + y(:,n_obj + n_var + 1 + i);
        end
        crowd_dist_var=crowd_dist_var./n_var;
        avg_crowd_dist_var=mean(crowd_dist_var);
    %% Calculate distance in objective space
        crowd_dist_obj = [];
        crowd_dist_obj(:,1) = zeros(length(F(front).f),1);
        for i = 1 : n_obj
            crowd_dist_obj(:,1) = crowd_dist_obj(:,1) + y(:,n_obj + n_var + 1+n_var + i);
        end
        crowd_dist_obj=crowd_dist_obj./n_obj;
        avg_crowd_dist_obj=mean(crowd_dist_obj);
    %% Calculate special crowding distance
        special_crowd_dist=zeros(length(F(front).f),1);
        for i = 1 : length(F(front).f)
            if crowd_dist_obj(i)>avg_crowd_dist_obj||crowd_dist_var(i)>avg_crowd_dist_var
                special_crowd_dist(i)=max(crowd_dist_obj(i),crowd_dist_var(i)); % Eq. (6) in the paper
            else
                special_crowd_dist(i)=min(crowd_dist_obj(i),crowd_dist_var(i)); % Eq. (7) in the paper
            end
        end
        y(:,n_obj + n_var + 2) = special_crowd_dist;
        y(:,n_obj+n_var+3)=crowd_dist_var;
        y(:,n_obj+n_var+4)=crowd_dist_obj;
        [~,index_sorted_based_crowddist]=sort(special_crowd_dist,'descend');%sort the particles in the same front according to SCD
        y=y(index_sorted_based_crowddist,:);
        y = y(:,1 : n_obj + n_var+4 );
        z(previous_index:current_index,:) = y;
    end
    
f = z();
end



%Write by Caitong Yue 2017.09.04
%Supervised by Jing Liang and Boyang Qu