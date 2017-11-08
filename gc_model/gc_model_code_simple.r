###########################################################################
###########################################################################
############## Created by Heather Kropp in October 2017      ##############
############## The model code for the analysis of the        ##############
############## of canopy stomatal conductance calculated     ##############
############## from sapflow. The model is based on a         ##############
############## phenomenological model that describes         ##############
############## stomatal responses to light and VPD           ##############
############## used in Kropp et. al. 2017, Oren et. al. 1999,##############
############## Jarvis 1976, and White et. al. 1999.          ##############
############## The parameters of this model are considered   ##############
############## to vary with environmental drivers:           ##############
############## average daily air temperature and antecedent  ##############
############## precipitation.                                ##############
###########################################################################
###########################################################################

model{
#################################
#########Model likelihood########
#################################
	for(i in 1:Nobs){
	#likelihood for each tree
	gs[i]~dnorm(mu.gs[i],tau.gs[stand.obs[i]])
	rep.gs[i]~dnorm(mu.gs[i],tau.gs[stand.obs[i]])
	
	#gs.rep[i]~dnorm(mu.gs[i],tau.gs)
	#model for mean gs
	mu.gs[i]<-oren.mod[i]*light[i]
	
	#light scaling function
	light[i]<-1-exp(-l.slope[standDay[i]]*PAR[i])
	
	#oren model 1999 for mean gs
	oren.mod[i]<-gref[standDay[i]]*(1-(S[standDay[i]]*log(D[i])))

	}
#################################
#########parameter model ########
#################################	
	for(i in 1:NstandDay){
		gref[i]<-a[1,stand[i]]+a[2,stand[i]]*airTcent[i]+a[3,stand[i]]*(pastpr[days[i],stand[i]]-5)+a[4,stand[i]]*(thawD[i]-thawstart[stand[i]])
		S[i]<-b[1,stand[i]]+b[2,stand[i]]*airTcent[i]+b[3,stand[i]]*(pastpr[days[i],stand[i]]-5)+b[4,stand[i]]*(thawD[i]-thawstart[stand[i]])
		slope.temp[i] <-d[1,stand[i]]+d[2,stand[i]]*airTcent[i]+d[3,stand[i]]*(pastpr[days[i],stand[i]]-5)+d[4,stand[i]]*(thawD[i]-thawstart[stand[i]])
		#Log transform light function slope to avoid numerical traps
		#and allow for better mixing and faster convergence of the non-linear model
		l.slope[i]<-exp(slope.temp[i])
	#conduct covariate centering to help with mixing

	airTcent[i]<-airT[i]-airTmean	

	#calculate sensitivity

	}
#################################
#########antecedent model########
#################################	
#Antecedent calculations based on Ogle et al 2015
	#calculate antecedent values for soil temp and soil water content
	for(j in 1:Nstand){
		for(m in 1:Nlag){
			#weights for precip
			deltapr[m,j]~dgamma(1,1)
			wpr[m,j]<-deltapr[m,j]/sumpr[j]
			#calculate weighted precip for each day in the past
			for(i in 1:Ndays){
				pr.temp[i,m,j]<-wpr[m,j]*a.pr[i,m]
			}
		}

	}
	#calculate sums of unweighted delta values

	sumpr[1]<-sum(deltapr[,1])
	sumpr[2]<-sum(deltapr[,2])

	#final antecedent calculations for soil values
	for(i in 1:Ndays){
		pastpr[i,1]<-sum(pr.temp[i,,1])
		pastpr[i,2]<-sum(pr.temp[i,,2])
	}
	
		

#################################
#########priors          ########
#################################	
	#define prior distributions for parameters
	#All parameters are given non-informative dist
	

	for(i in 1:Nstand){
		
		tau.gs[i]<-pow(sig.gs[i],-2)
		sig.gs[i]~dunif(0,1000)	
		
		
	}

#################################
#########antecedent model########
#########mixing tricks   ########
#################################
for(i in 1:Nstand){
	for(j in 1:Nparm){
	a[j,i] ~dnorm(aa[j,i], tau.aa[j,i])
	aa.star[j,i]<- (a[j,i]*(noAnt[j]*sumDeltas[i]))+(a[j,i]*(1-noAnt[j]))
	aa[j,i] ~dnorm(0,.001)
	tau.aa[j,i] <- pow(sig.aa[j,i],-2)
	sig.aa[j,i] ~ dunif(0,100)
	b[j,i] ~dnorm(bb[j,i], tau.bb[j,i])
	bb.star[j,i]<- (b[j,i]*(noAnt[j]*sumDeltas[i]))+(b[j,i]*(1-noAnt[j]))
	bb[j,i] ~dnorm(0,.001)
	tau.bb[j,i] <- pow(sig.bb[j,i],-2)
	sig.bb[j,i] ~ dunif(0,100)
	d[j,i] ~dnorm(dd[j,i], tau.dd[j,i])
	dd.star[j,i]<- (d[j,i]*(noAnt[j]*sumDeltas[i]))+(b[j,i]*(1-noAnt[j]))
	dd[j,i] ~dnorm(0,.001)
	tau.dd[j,i] <- pow(sig.dd[j,i],-2)
	sig.dd[j,i] ~ dunif(0,100)
	
	}
	
	sumDeltas[i] <- sumpr[i]
}
for(j in 1:Nparm){
	noAnt[j] <- equals(j,3)
}	
	
}	