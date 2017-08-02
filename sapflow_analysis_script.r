######################################
##script for sapflow calculations ####
##and subsequent analysis for     ####
##density gradient sapflow        ####
######################################


library(lubridate)
library(plyr)
library(caTools)

setwd("c:\\Users\\hkropp\\Google Drive\\Viper_SF")

#read in TDP 
#not these files are truncated to start at 5am
#on first day of a full data measurement with no
#start up data included in the first day of data
#high density
datDTH <- read.csv("high_density_TDP.csv")
#low density
datDTL <- read.csv("low_density_TDP.csv")

#high density 2017
datDTH17 <- read.table("HD_TDP_DT.csv", sep=",", head=TRUE, na.strings=c("NAN"))
#low density 2017
datDTL17 <- read.table("LD_TDP_DT.csv", sep=",", head=TRUE, na.strings=c("NAN"))
#read in sensor info
datS <- read.csv("sensor_info.csv")

#read in 2017 sensor info
datS17<-read.csv("sensor_info17.csv")

##### read in sapwood thickness or sensor correciton
datSW <- read.csv("sap_thick.csv")

####met data for both sites
datLmet<-read.csv("c:\\Users\\hkropp\\Google Drive\\Viper_SF\\csv_out\\LDF2RS.csv.csv")
datHmet<-read.csv("c:\\Users\\hkropp\\Google Drive\\Viper_SF\\csv_out\\DavCnpy.csv.csv")

#airport met data
datAD<-read.table("airport.csv", sep=";", head=TRUE, skip=6, stringsAsFactors=FALSE)

#water potential data
datwp<-read.csv("waterpotential.csv")

#sensors 9-16 were run at the incorrect voltage
#and clearly have incorrect dT values for it
#so excluding from calculations
datH <- datDTH[,5:(4+8)]
datL <- datDTL[,5:dim(datDTL)[2]]
datH17 <- datDTH17[,7:22]
datL17 <- datDTL17[,7:22]
#set up date
dateDH <- as.Date(datDTH$TIMESTAMP, "%m/%d/%Y %H:%M")
dateDL <- as.Date(datDTL$TIMESTAMP, "%m/%d/%Y %H:%M")
dateDH17 <- as.Date(datDTH17$TIMESTAMP, "%m/%d/%Y %H:%M")
dateDL17 <- as.Date(datDTL17$TIMESTAMP, "%m/%d/%Y %H:%M")

doyDH <- yday(dateDH)
doyDL <- yday(dateDL)
doyDH17 <- yday(dateDH17)
doyDL17 <- yday(dateDL17)

#convert time
timeDH <- ifelse(datDTH$JHM/100-floor(datDTH$JHM/100)==0,datDTH$JHM/100,floor(datDTH$JHM/100)+.5)
timeDL <- ifelse(datDTL$JHM/100-floor(datDTL$JHM/100)==0,datDTL$JHM/100,floor(datDTL$JHM/100)+.5)
#convert minutues to demicamal in 2017
timeDL17<-datDTL17$hour+(datDTL17$minute/60)
timeDH17<-datDTH17$hour+(datDTH17$minute/60)
#need to create new doy index that defines day of year between 5am and 5am
#for defining intervals that would count refil as in the same day
datL$doy <- ifelse(timeDL<5,doyDL-1,doyDL)
datH$doy <- ifelse(timeDH<5,doyDH-1,doyDH)
datL17$doy <- ifelse(timeDL17<5,doyDL17-1,doyDL17)
datH17$doy <- ifelse(timeDH17<5,doyDH17-1,doyDH17)


#get the unique dayid for each stand
#get the number of observations in a day for each stand
DaysL <- aggregate(datL$doy, by=list(datL$doy), FUN="length")
colnames(DaysL) <- c("doy", "nobs")
DaysL$dayid <- seq(1,dim(DaysL)[1])

DaysH <- aggregate(datH$doy, by=list(datH$doy), FUN="length")
colnames(DaysH) <- c("doy", "nobs")
DaysH$dayid <-  seq(1, dim(DaysH)[1])	

DaysL17 <- aggregate(datL17$doy, by=list(datL17$doy), FUN="length")
colnames(DaysL17) <- c("doy", "nobs")
DaysL17$dayid <- seq(1,dim(DaysL17)[1])

DaysH17 <- aggregate(datH17$doy, by=list(datH17$doy), FUN="length")
colnames(DaysH17) <- c("doy", "nobs")
DaysH17$dayid <-  seq(1, dim(DaysH17)[1])

###########
####calculate the max dT in a day
#low density
#and 2017 data
maxDTL <- matrix(rep(NA,dim(DaysL)[1]*16),ncol=16)
maxDTL17 <- matrix(rep(NA,dim(DaysL17)[1]*16),ncol=16)
maxDTH17 <- matrix(rep(NA,dim(DaysH17)[1]*16),ncol=16)
#output matrix of the max per each day
for(j in 1:16){
	for(i in 1:dim(DaysL)[1]){
		maxDTL[i,j] <- max(na.omit(datL[datL$doy==DaysL$doy[i],j]))
	}
	
	for(i in 1:dim(DaysL17)[1]){
		if(length(na.omit(datL17[datL17$doy==DaysL17$doy[i],j]))!=0){
			maxDTL17[i,j] <- max(na.omit(datL17[datL17$doy==DaysL17$doy[i],j]))
		}
	}
	for(i in 1:dim(DaysH17)[1]){
		maxDTH17[i,j] <- max(na.omit(datH17[datH17$doy==DaysH17$doy[i],j]))
	}
}
#calcuate high density 2016
maxDTH <- matrix(rep(0,dim(DaysH)[1]*8),ncol=8)

for(j in 1:8){
	for(i in 1:dim(DaysH)[1]){
		maxDTH[i,j] <- max(na.omit(datH[datH$doy==DaysH$doy[i],j]))
	}
}
maxDTL <- as.data.frame(maxDTL)
maxDTL$doy <- DaysL$doy

maxDTH <- as.data.frame(maxDTH)
maxDTH$doy <- DaysH$doy

maxDTL17 <- as.data.frame(maxDTL17)
maxDTL17$doy <- DaysL17$doy

maxDTH17 <- as.data.frame(maxDTH17)
maxDTH17$doy <- DaysH17$doy

# now combine both
datAH <- join(datH,maxDTH, by=c("doy"), type="left")
datAL <- join(datL,maxDTL, by=c("doy"), type="left")

datAH17 <- join(datH17,maxDTH17, by=c("doy"), type="left")
datAL17 <- join(datL17,maxDTL17, by=c("doy"), type="left")

###################################################
##### sapwood thickness and sensor correction

#fit a linear regression for sap thickness
#low
lmSWL <- lm(datSW$SWT[datSW$stand=="LDF2"]~datSW$DBH[datSW$stand=="LDF2"])
summary(lmSWL)
#high
lmSWH <- lm(datSW$SWT[datSW$stand=="DAV"]~datSW$DBH[datSW$stand=="DAV"])
summary(lmSWH)
#fit a linear regression for bark thickness
#low
lmBL <- lm(datSW$Bark[datSW$stand=="LDF2"]~datSW$DBH[datSW$stand=="LDF2"])
summary(lmBL)
#high
lmBH <- lm(datSW$Bark[datSW$stand=="DAV"]~datSW$DBH[datSW$stand=="DAV"])
summary(lmBH)
#looks like sapwood thickness varies with stand
#predict the sapwood thickness for the trees that had sensors
datS$SWT <- ifelse(datS$stand=="high", coefficients(lmSWH)[1]+(coefficients(lmSWH)[2]*datS$DBH),
				coefficients(lmSWL)[1]+(coefficients(lmSWL)[2]*datS$DBH))

datS$Bark <- ifelse(datS$stand=="high", coefficients(lmBH)[1]+(coefficients(lmBH)[2]*datS$DBH),
				coefficients(lmBL)[1]+(coefficients(lmBL)[2]*datS$DBH))		

datS17$SWT <- ifelse(datS17$stand=="hd", coefficients(lmSWH)[1]+(coefficients(lmSWH)[2]*datS17$DBH..cm.),
				coefficients(lmSWL)[1]+(coefficients(lmSWL)[2]*datS17$DBH..cm.))

datS17$Bark <- ifelse(datS$stand=="hd", coefficients(lmBH)[1]+(coefficients(lmBH)[2]*datS17$DBH..cm.),
				coefficients(lmBL)[1]+(coefficients(lmBL)[2]*datS17$DBH..cm.))		

				
#calculate the heartwood 			
datS$Htwd <- datS$DBH-(datS$Bark*2)-(datS$SWT*2)

datS17$Htwd <- datS17$DBH-(datS17$Bark*2)-(datS17$SWT*2)
#calculate sapwood area
datS$sapA <- (pi*(((datS$SWT/2)+(datS$Htwd/2))^2))-(pi*((datS$Htwd/2)^2))

datS17$sapA <- (pi*(((datS17$SWT/2)+(datS17$Htwd/2))^2))-(pi*((datS17$Htwd/2)^2))		
								
#now calculate the porportion of the sensor in sapwood
SensDiff <- datS$Sensor.length-datS$SWT
	
SensDiff17 <- datS17$Sensor.length-datS17$SWT	
#if value is negative, it means that the sapwood is thicker than the sensor length
#so it doesn't need to be corrected

#b represents the proption of the probe not in sapwood
datS$b <- ifelse(SensDiff>0,SensDiff/datS$Sensor.length,0)
datS$a <- 1-datS$b

datS17$b <- ifelse(SensDiff17>0,SensDiff17/datS17$Sensor.length,0)
datS17$a <- 1-datS17$b
#seperate df
datSH <- datS[datS$stand=="high",]
datSL <- datS[datS$stand=="low",]

datSH17 <- datS17[datS17$stand=="hd",]
datSL17 <- datS17[datS17$stand=="ld",]
#only sensors 1-8 were at the right voltage
datSH <- datSH[1:8,]

###########corrected dT value with sapwood
#now calcualte a corrected dt value based on sensor length
#note when b=0 and a=1 the dT corrected is equal to the raw dT
dTcorrL<-matrix(rep(NA,dim(datAL)[1]*16), ncol=16)
dTcorrH<-matrix(rep(NA,dim(datAH)[1]*8), ncol=8)
dTcorrL17<-matrix(rep(NA,dim(datAL17)[1]*16), ncol=16)
dTcorrH17<-matrix(rep(NA,dim(datAH17)[1]*16), ncol=16)
for(i in 1:16){
		dTcorrL[,i] <- (datAL[,i]-(datSL$b[i]*datAL[,17+i]))/datSL$a[i]	
		dTcorrL17[,i] <- (datAL17[,i]-(datSL17$b[i]*datAL17[,17+i]))/datSL17$a[i]	
		dTcorrH17[,i]<- (datAH17[,i]-(datSH17$b[i]*datAH17[,17+i]))/datSH17$a[i]	
		}
for(i in 1:8){

		dTcorrH[,i]<- (datAH[,i]-(datSH$b[i]*datAH[,9+i]))/datSH$a[i]	
}

#T diff calculation
#Tmax-dtcor/dtcor
KL<-matrix(rep(NA,dim(datAL)[1]*16), ncol=16)
KH<-matrix(rep(NA,dim(datAH)[1]*8), ncol=8)
KL17<-matrix(rep(NA,dim(datAL17)[1]*16), ncol=16)
KH17<-matrix(rep(NA,dim(datAH17)[1]*16), ncol=16)
#low
for(i in 1:16){
		KL[,i] <- (datAL[,17+i]-dTcorrL[,i])/dTcorrL[,i]	
		KL17[,i] <- (datAL17[,17+i]-dTcorrL17[,i])/dTcorrL17[,i]
		KH17[,i] <- (datAH17[,17+i]-dTcorrH17[,i])/dTcorrH17[,i]			
}
#high
for(i in 1:8){
		KH[,i] <- (datAH[,9+i]-dTcorrH[,i])/dTcorrH[,i]	
}
#calculate velocity in cm/ s
V.h<-matrix(rep(0,dim(KH)[1]*8), ncol=8)
V.l<-matrix(rep(0,dim(KL)[1]*16), ncol=16)
V.h17<-matrix(rep(0,dim(KH17)[1]*16), ncol=16)
V.l17<-matrix(rep(0,dim(KL17)[1]*16), ncol=16)
#high
for(i in 1:8){
	V.h[,i] <- ifelse(KH[,i]>=0,0.0119*(KH[,i]^1.231),NA)

}
#low	
for(i in 1:16){
	V.l[,i] <- ifelse(KL[,i]>=0,0.0119*(KL[,i]^1.231),NA)
	V.h17[,i] <- ifelse(KH17[,i]>=0,0.0119*(KH17[,i]^1.231),NA)
	V.l17[,i] <- ifelse(KL17[,i]>=0,0.0119*(KL17[,i]^1.231),NA)
}

	#turn sensor 1 in low 17 to NA until day 170 because the sensor
	#was switched and that is the info used 
	
	V.l17[,1]<-ifelse(doyDL17<170,NA,V.l17[,1])

######END Corrected velocity done with V.h and V.l ##############
#plot all sensors
#for(i in 1:16){
#	jpeg(file=paste0("c:\\Users\\hkropp\\Google Drive\\Viper_SF\\plots\\new\\velocity\\low16\\velocity", i, ".jpeg"), width=1500, height=1000, units="px")
#	plot(seq(1:dim(V.l)[1]), V.l[,i], xlab="time", ylab="V (cm/s)", type="b",
#			main=paste("sensor #", i), pch=19)
#	dev.off()
#}
#for(i in 1:16){
#	jpeg(file=paste0("c:\\Users\\hkropp\\Google Drive\\Viper_SF\\plots\\new\\velocity\\low17\\velocity", i, ".jpeg"), width=1500, height=1000, units="px")
#	plot(seq(1:dim(V.l17)[1]), V.l17[,i], xlab="time", ylab="V (cm/s)", type="b",
#			main=paste("sensor #", i), pch=19)
#	dev.off()
#}
#for(i in 1:16){
#	jpeg(file=paste0("c:\\Users\\hkropp\\Google Drive\\Viper_SF\\plots\\new\\velocity\\high17\\velocity", i, ".jpeg"), width=1500, height=1000, units="px")
#	plot(seq(1:dim(V.h17)[1]), V.h17[,i], xlab="time", ylab="V (cm/s)", type="b",
#			main=paste("sensor #", i), pch=19)
#	dev.off()
#}
#high
#for(i in 1:8){
#	jpeg(file=paste0("c:\\Users\\hkropp\\Google Drive\\Viper_SF\\plots\\new\\velocity\\high16\\velocity", i, ".jpeg"), width=1500, height=1000, units="px")
#	plot(seq(1:dim(V.h)[1]), V.h[,i], xlab="time", ylab="V (cm/s)", type="b",
#			main=paste("sensor #", i), pch=19)
#	dev.off()
#}

#################################################################
########Compare N and S velocities  #############################
#################################################################
#paired sensor numbers
LNorthS<-c(5,8,11)
LSouthS<-c(6,9,12)
LNorth17S<-c(5,11,15)
LSouth17S<-c(1,12,16)
HNorthS<-c(3)
HSouthS<-c(4)
HNorth17S<-c(3,5,11)
HSouth17S<-c(4,6,12)
#pull out sensor comparisionts

LNorth<-c(as.vector(V.l[,LNorthS]),as.vector(V.l17[,LNorth17S]))
LSouth<-c(as.vector(V.l[,LSouthS]),as.vector(V.l17[,LSouth17S]))

HNorth<-c(as.vector(V.h[,3]),as.vector(V.h17[,HNorth17S]))
HSouth<-c(as.vector(V.h[,4]),as.vector(V.h17[,HSouth17S]))

LNorth1<-c(as.vector(V.l[,5]),as.vector(V.l17[,5]))
LSouth1<-c(as.vector(V.l[,6]),as.vector(V.l17[,1]))
LNorth2<-c(as.vector(V.l[,8]),as.vector(V.l17[,11]))
LSouth2<-c(as.vector(V.l[,9]),as.vector(V.l17[,12]))
LNorth3<-c(as.vector(V.l[,11]),as.vector(V.l17[,15]))
LSouth3<-c(as.vector(V.l[,12]),as.vector(V.l17[,16]))

HNorth1<-c(as.vector(V.h[,3]),as.vector(V.h17[,3]))
HSouth1<-c(as.vector(V.h[,4]),as.vector(V.h17[,4]))
HNorth2<-c(as.vector(V.h17[,5]))
HSouth2<-c(as.vector(V.h17[,6]))
HNorth3<-c(as.vector(V.h17[,11]))
HSouth3<-c(as.vector(V.h17[,12]))


LNorth<-ifelse(LNorth>quantile(LNorth, probs=.9, na.rm=TRUE),NA,LNorth)
LSouth<-ifelse(LSouth>quantile(LSouth, probs=.9, na.rm=TRUE),NA,LSouth)

LNorth1<-ifelse(LNorth1>quantile(LNorth1, probs=.9, na.rm=TRUE),NA,LNorth1)
LSouth1<-ifelse(LSouth1>quantile(LSouth1, probs=.9, na.rm=TRUE),NA,LSouth1)
LNorth2<-ifelse(LNorth2>quantile(LNorth2, probs=.9, na.rm=TRUE),NA,LNorth2)
LSouth2<-ifelse(LSouth2>quantile(LSouth2, probs=.9, na.rm=TRUE),NA,LSouth2)
LNorth3<-ifelse(LNorth3>quantile(LNorth3, probs=.9, na.rm=TRUE),NA,LNorth3)
LSouth3<-ifelse(LSouth3>quantile(LSouth3, probs=.9, na.rm=TRUE),NA,LSouth3)

##high density
##filter extreme values

HNorth<-ifelse(HNorth>quantile(HNorth, probs=.9, na.rm=TRUE),NA,HNorth)
HSouth<-ifelse(HSouth>quantile(HSouth, probs=.9, na.rm=TRUE),NA,HSouth)

HNorth1<-ifelse(HNorth1>quantile(HNorth1, probs=.9, na.rm=TRUE),NA,HNorth1)
HSouth1<-ifelse(HSouth1>quantile(HSouth1, probs=.9, na.rm=TRUE),NA,HSouth1)

HNorth2<-ifelse(HNorth2>quantile(HNorth2, probs=.9, na.rm=TRUE),NA,HNorth2)
HSouth2<-ifelse(HSouth2>quantile(HSouth2, probs=.9, na.rm=TRUE),NA,HSouth2)

HNorth3<-ifelse(HNorth3>quantile(HNorth3, probs=.9, na.rm=TRUE),NA,HNorth3)
HSouth3<-ifelse(HSouth3>quantile(HSouth3, probs=.9, na.rm=TRUE),NA,HSouth3)

#check all trees together in each stand
par(mfrow=c(1,2))
plot(HNorth,HSouth, ylim=c(0,.01), xlim=c(0,.01))
plot(LNorth,LSouth)

AspNH<-lm(HSouth~HNorth)
summary(AspNH)

AspNL<-lm(LSouth~LNorth)
summary(AspNL)

##check low density individual trees
par(mfrow=c(1,3))
plot(LNorth1,LSouth1)
plot(LNorth2,LSouth2)
plot(LNorth3,LSouth3)

AspNL1<-lm(LSouth1~LNorth1)
summary(AspNL1)
AspNL2<-lm(LSouth2~LNorth2)
summary(AspNL2)
AspNL3<-lm(LSouth3~LNorth3)
summary(AspNL3)

##check high density individual trees
par(mfrow=c(1,3))
plot(HNorth1,HSouth1)
plot(HNorth2,HSouth2)
plot(HNorth3,HSouth3)

AspNH1<-lm(HSouth1~HNorth1)
summary(AspNH1)

AspNH2<-lm(HSouth2~HNorth2)
summary(AspNH2)
AspNH3<-lm(HSouth3~HNorth3)
summary(AspNH3)

##tree by tree numbers are really variable
##some are insiginifcant and others are significant
## and the correlations vary by trees 

##for the stand regressions, the regressions are significant
##but the R2 are generally low (0.25 and .44) with a huge amount
##of variation. Each relationship has points everywhere filling the
##entire plot with only a very weak correlation visable
##For now treating N and S as something to average over including trees
##a more detailed discussion is needed.

#################################################################
###### calculate transpiration                  #################
#################################################################

#now calculate flow in  in g per s

F.h<-matrix(rep(0,dim(KH)[1]*8), ncol=8)
F.hf<-matrix(rep(0,dim(KH)[1]*8), ncol=8)
F.lf17<-matrix(rep(0,dim(KL17)[1]*16), ncol=16)
F.l17<-matrix(rep(0,dim(KL17)[1]*16), ncol=16)
F.lf<-matrix(rep(0,dim(KL)[1]*16), ncol=16)
F.l<-matrix(rep(0,dim(KL)[1]*16), ncol=16)
F.hf17<-matrix(rep(0,dim(KH17)[1]*16), ncol=16)
F.h17<-matrix(rep(0,dim(KH17)[1]*16), ncol=16)
########################################
########################################
########FILTER POINT 1   ###############
########Quantile filter  ###############
########################################

for(i in 1:16){
	#filter for values above the 95% 
	#filtering at 0.9 seems to remove some values in the a realistic range
	#of the data
	F.l[,i]<-V.l[,i]*datSL$sapA[i]
	F.lf[,i]<-ifelse(F.l[,i]<quantile(F.l[,i],probs=c(0.95),na.rm=TRUE),F.l[,i],NA)
	F.l17[,i]<-V.l17[,i]*datSL17$sapA[i]
	F.lf17[,i]<-ifelse(F.l17[,i]<quantile(F.l17[,i],probs=c(0.95),na.rm=TRUE),F.l17[,i],NA)	
	F.h17[,i]<-V.h17[,i]*datSH17$sapA[i]
	F.hf17[,i]<-ifelse(F.h17[,i]<quantile(F.h17[,i],probs=c(0.95),na.rm=TRUE),F.h17[,i],NA)
}	
for(i in 1:8){

	F.h[,i]<-V.h[,i]*datSH$sapA[i]
	F.hf[,i]<-ifelse(F.h[,i]<quantile(F.h[,i],probs=c(0.95),na.rm=TRUE),F.h[,i],NA)
	}

###########################################
##normalize by leaf area for transpiration
###########################################

 #leaf area calc for larch
 #allometry from Alexander 2012
leaf.bio<-function(DBH,a.leaf,b.leaf){a.leaf*(DBH^b.leaf)}
datSL$leafwt<-leaf.bio(datSL$DBH,40.5,1.41)	
#larch cm2/g
datSL$leaf<-datSL$leafwt*143
#convert to m2 
datSL$leafm2<-datSL$leaf*.0001


datSL17$leafwt<-leaf.bio(datSL17$DBH..cm.,40.5,1.41)	
#larch cm2/g
datSL17$leaf<-datSL17$leafwt*143
#convert to m2 
datSL17$leafm2<-datSL17$leaf*.0001

#high density calcs
datSH$leafwt<-leaf.bio(datSH$DBH,40.5,1.41)	
datSH$leaf<-datSH$leafwt*143
datSH$leafm2<-datSH$leaf*.0001

datSH17$leafwt<-leaf.bio(datSH17$DBH..cm.,40.5,1.41)	
datSH17$leaf<-datSH17$leafwt*143
datSH17$leafm2<-datSH17$leaf*.0001

########################################
########################################
########FILTER POINT2    ###############
########Quantile filter  ###############
########################################

#now calculate in g m-2 s
T.gL<-matrix(rep(0,dim(KL)[1]*16), ncol=16)
T.gH17<-matrix(rep(0,dim(KH17)[1]*16), ncol=16)
T.gHf17<-matrix(rep(0,dim(KH17)[1]*16), ncol=16)
T.gLf<-matrix(rep(0,dim(KL)[1]*16), ncol=16)
T.gL17<-matrix(rep(0,dim(KL17)[1]*16), ncol=16)
T.gLf17<-matrix(rep(0,dim(KL17)[1]*16), ncol=16)
T.gH<-matrix(rep(0,dim(KH)[1]*8), ncol=8)
T.gHf<-matrix(rep(0,dim(KH)[1]*8), ncol=8)
for(i in 1:8){
	T.gH[,i]<-F.hf[,i]/datSH$leafm2[i]
	T.gHf[,i]<-ifelse(T.gH[,i]<quantile(T.gH[,i],probs=c(0.95),na.rm=TRUE),T.gH[,i],NA)
	
}
for(i in 1:16){
	T.gL[,i]<-F.lf[,i]/datSL$leafm2[i]	
	T.gLf[,i]<-ifelse(T.gL[,i]<quantile(T.gL[,i],probs=c(0.95),na.rm=TRUE),T.gL[,i],NA)
	T.gL17[,i]<-F.lf17[,i]/datSL17$leafm2[i]	
	T.gLf17[,i]<-ifelse(T.gL17[,i]<quantile(T.gL17[,i],probs=c(0.95),na.rm=TRUE),T.gL17[,i],NA)
	T.gH17[,i]<-F.hf17[,i]/datSH17$leafm2[i]
	T.gHf17[,i]<-ifelse(T.gH17[,i]<quantile(T.gH17[,i],probs=c(0.95),na.rm=TRUE),T.gH17[,i],NA)
}

#create a dataframe
El.H<-data.frame(doy=doyDH, year=rep(2016,length(doyDH)),T.gHf[,1:8])

El.L<-data.frame(doy=doyDL, year=rep(2016,length(doyDL)),T.gLf[,1:16])

El.H17<-data.frame(doy=doyDH17, year=rep(2017,length(doyDH17)),T.gHf17[,1:16])

El.L17<-data.frame(doy=doyDL17, year=rep(2017,length(doyDL17)),T.gLf17[,1:16])

#########End Transpiration (T) calcs ####################

#########################################################
######calculate stomatal conductance ####################
#########################################################

#join air pressure to each met table
#get date from each
dateAP<-as.Date(rownames(datAD), "%d.%m.%Y %H:%M")
#make a data frame that is pressure
#Po is the air pressure but the headers get
# shifted in the format so the row name is
# T

datPhh<-data.frame(doy=yday(dateAP),year=year(dateAP), Pkpa= datAD$T/7.474)

datPj<-aggregate(datPhh$Pkpa, by=list(datPhh$doy, datPhh$year), FUN="mean")
colnames(datPj)<-c("doy","year","Pkpa")

datLmet<-join(datLmet, datPj, by=c("doy", "year"), type="left")
datHmet<-join(datHmet, datPj, by=c("doy", "year"), type="left")



#data frame of T in kg m-2 s-1
datLc1<-data.frame(doy=doyDL,year=rep(2016, length(doyDL)),hour=timeDL,T.gLf/1000)
datHc1<-data.frame(doy=doyDH,year=rep(2016, length(doyDH)),hour=timeDH,T.gHf/1000)

datL17c1<-data.frame(doy=doyDL17,year=rep(2017, length(doyDL17)), hour=timeDL17,T.gLf17/1000)
datH17c1<-data.frame(doy=doyDH17,year=rep(2017, length(doyDH17)), hour=timeDH17,T.gHf17/1000)

#join met data to T
datLtkg<-join(datLc1,datLmet, by=c("doy","year","hour"), type="left")
datHtkg<-join(datHc1,datHmet, by=c("doy","year","hour"), type="left")

datLtkg17<-join(datL17c1,datLmet, by=c("doy","year","hour"), type="inner")
datHtkg17<-join(datH17c1,datHmet, by=c("doy","year","hour"), type="left")

#calculate saturated vapor pressure
datLe.sat<-0.611*exp((17.502*datLtkg$Temp)/(datLtkg$Temp+240.97))
datHe.sat<-0.611*exp((17.502*datHtkg$Ctemp)/(datHtkg$Ctemp+240.97))
datL17e.sat<-0.611*exp((17.502*datLtkg17$Temp)/(datLtkg17$Temp+240.97))
datH17e.sat<-0.611*exp((17.502*datHtkg17$Ctemp)/(datHtkg17$Ctemp+240.97))

#calculate vapor pressure deficit
#here rh is is in decimal form 
datLtkg$RHfix<-ifelse(datLtkg$RH>=1,.999,datLtkg$RH)
datHtkg$RHfix<-ifelse(datHtkg$RH>=1,.999,datHtkg$RH)
datLtkg17$RHfix<-ifelse(datLtkg17$RH>=1,.999,datLtkg17$RH)
datHtkg17$RHfix<-ifelse(datHtkg17$RH>=1,.999,datHtkg17$RH)


datLtkg$D<-(datLe.sat-(datLtkg$RHfix*datLe.sat))
datHtkg$D<-(datHe.sat-(datHtkg$RHfix*datHe.sat))
datLtkg17$D<-(datL17e.sat-(datLtkg17$RHfix*datL17e.sat))
datHtkg17$D<-(datH17e.sat-(datHtkg17$RHfix*datH17e.sat))

Kg.coeff<-function(T){115.8+(.423*T)}
datLtkg$Kg<-Kg.coeff(datLtkg$Temp)
datHtkg$Kg<-Kg.coeff(datHtkg$Ctemp)

datLtkg17$Kg<-Kg.coeff(datLtkg17$Temp)
datHtkg17$Kg<-Kg.coeff(datHtkg17$Ctemp)
#convert to gs
Gs.convert1<-function(Kg,El,D,P){((Kg*El)/D)*P}
#change units to moles
unit.conv<-function(gs,T,P){gs*.446*(273/(T+273))*(P/101.3)}

Gshigh<-matrix(rep(0,dim(KH)[1]*8), ncol=8)
Gslow<-matrix(rep(0,dim(KL)[1]*16), ncol=16)
Gshighmm<-matrix(rep(0,dim(KH)[1]*8), ncol=8)
Gslowmm<-matrix(rep(0,dim(KL)[1]*16), ncol=16)
Gshighf<-matrix(rep(0,dim(KH)[1]*8), ncol=8)
Gslowf<-matrix(rep(0,dim(KL)[1]*16), ncol=16)


Gshigh17<-matrix(rep(0,dim(KH17)[1]*16), ncol=16)
Gslow17<-matrix(rep(0,dim(datLtkg17)[1]*16), ncol=16)
Gshighmm17<-matrix(rep(0,dim(KH17)[1]*16), ncol=16)
Gslowmm17<-matrix(rep(0,dim(datLtkg17)[1]*16), ncol=16)
Gshighf17<-matrix(rep(0,dim(KH17)[1]*16), ncol=16)
Gslowf17<-matrix(rep(0,dim(datLtkg17)[1]*16), ncol=16)

########################################
########################################
########FILTER POINT 3   ###############
########Range filter     ###############
########################################
for(i in 1:8){
	Gshigh[,i]<-Gs.convert1(datHtkg$Kg,datHtkg[,i+3],datHtkg$D, datHtkg$Pkpa)
	Gshighmm[,i]<-unit.conv(Gshigh[,i],datHtkg$Ctemp, datHtkg$Pkpa)*1000
	Gshighf[,i]<-ifelse(Gshighmm[,i]<400,Gshighmm[,i],NA)
}	
for(i in 1:16){	
	Gslow[,i]<-Gs.convert1(datLtkg$Kg,datLtkg[,i+3],datLtkg$D, datLtkg$Pkpa)
	Gslowmm[,i]<-unit.conv(Gslow[,i],datLtkg$Temp, datLtkg$Pkpa)*1000
	Gslowf[,i]<-ifelse(Gslowmm[,i]<400,Gslowmm[,i],NA)
	
	Gshigh17[,i]<-Gs.convert1(datHtkg17$Kg,datHtkg17[,i+3],datHtkg17$D, datHtkg17$Pkpa)
	Gshighmm17[,i]<-unit.conv(Gshigh17[,i],datHtkg17$Ctemp, datHtkg17$Pkpa)*1000
	Gshighf17[,i]<-ifelse(Gshighmm17[,i]<400,Gshighmm17[,i],NA)
	
	Gslow17[,i]<-Gs.convert1(datLtkg17$Kg,datLtkg17[,i+3],datLtkg17$D, datLtkg17$Pkpa)
	Gslowmm17[,i]<-unit.conv(Gslow17[,i],datLtkg17$Temp, datLtkg17$Pkpa)*1000
	Gslowf17[,i]<-ifelse(Gslowmm17[,i]<400,Gslowmm17[,i],NA)
}

#create a dataframe
gc.H<-data.frame(doy=doyDH, year=rep(2016,length(doyDH)),Gshighf[,1:8])
#exclude sensor 1 because it is very high and can't be verified 
gc.L<-data.frame(doy=doyDL, year=rep(2016,length(doyDL)),Gslowf[,1:16])

gc.H17<-data.frame(doy=doyDH17, year=rep(2017,length(doyDH17)),Gshighf17[,1:8])
#exclude sensor 1 because it is very high and can't be verified 
gc.L17<-data.frame(doy=doyDL17, year=rep(2017,length(doyDL17)),Gslowf17[,1:16])


###########END of canopy stomatal conductance calc ############

###################################################################################
###################################################################################
############### Average across each sensor                            #############
###################################################################################

################################
#####Canopy T

#get average value excluding na
mEl.H<-data.frame(doy=doyDH,year=El.H$year,hour=timeDH, El=rowMeans(El.H[,3:10],na.rm=TRUE))
mEl.L<-data.frame(doy=doyDL,year=El.L$year,hour=timeDL, El=rowMeans(El.L[,3:18],na.rm=TRUE))
mEl.H17<-data.frame(doy=doyDH17,year=El.H17$year,hour=timeDH17, El=rowMeans(El.H17[,3:18],na.rm=TRUE))
mEl.L17<-data.frame(doy=doyDL17,year=El.L17$year,hour=timeDL17, El=rowMeans(El.L17[,3:18],na.rm=TRUE))

#count how many observations are in each time period
#so that any observations with less than 3 sensor obs can
#be excluded
Hna<-apply(El.H[,3:10],2,is.na)
Hna.c<-apply(Hna[,1:8],1,sum)
Hflag<-ifelse(Hna.c>6,1,0)

Lna<-apply(El.L[,3:18],2,is.na)
Lna.c<-apply(Lna[,1:16],1,sum)
Lflag<-ifelse(Lna.c>14,1,0)

Hna17<-apply(El.H17[,3:10],2,is.na)
Hna.c17<-apply(Hna17[,1:8],1,sum)
Hflag17<-ifelse(Hna.c17>6,1,0)

Lna17<-apply(El.L17[,3:18],2,is.na)
Lna.c17<-apply(Lna17[,1:16],1,sum)
Lflag17<-ifelse(Lna.c17>14,1,0)

#now turn any means into NA without sufficient obs
mEl.L$El<-ifelse(Lflag==1,NA,mEl.L$El)
mEl.L17$El<-ifelse(Lflag17==1,NA,mEl.L17$El)
mEl.H$El<-ifelse(Hflag==1,NA,mEl.H$El)
mEl.H17$El<-ifelse(Hflag17==1,NA,mEl.H17$El)

###############################
### gc
mgc.H<-data.frame(doy=doyDH,year=El.H$year,hour=timeDH, gc=rowMeans(Gshighf[,1:8],na.rm=TRUE))
mgc.L<-data.frame(doy=doyDL,year=El.L$year,hour=timeDL, gc=rowMeans(Gslowf[,1:16],na.rm=TRUE))
mgc.H17<-data.frame(doy=doyDH17,year=El.H17$year,hour=timeDH17, gc=rowMeans(Gshighf17[,1:16],na.rm=TRUE))
mgc.L17<-data.frame(doy=doyDL17,year=El.L17$year,hour=timeDL17, gc=rowMeans(Gslowf17[,1:16],na.rm=TRUE))

#set up flags
gHna<-apply(Gshighf[,1:8],2,is.na)
gHna.c<-apply(gHna[,1:8],1,sum)
gHflag<-ifelse(gHna.c>6,1,0)

gLna<-apply(Gslowf[,1:16],2,is.na)
gLna.c<-apply(gLna[,1:16],1,sum)
gLflag<-ifelse(gLna.c>14,1,0)

gHna17<-apply(Gshighf17[,1:16],2,is.na)
gHna.c17<-apply(gHna17[,1:16],1,sum)
gHflag17<-ifelse(gHna.c17>14,1,0)

gLna17<-apply(Gslowf17[,1:16],2,is.na)
gLna.c17<-apply(gLna17[,1:16],1,sum)
gLflag17<-ifelse(gLna.c17>14,1,0)

#use flags to make na for anything with insufficient
#observation count
mgc.L$gc<-ifelse(gLflag==1,NA,mgc.L$gc)
mgc.H$gc<-ifelse(gHflag==1,NA,mgc.H$gc)
mgc.L17$gc<-ifelse(gLflag17==1,NA,mgc.L17$gc)
mgc.H17$gc<-ifelse(gHflag17==1,NA,mgc.H17$gc)




###############################################################
###Filter for unreliable sap flow days ########################
###d

#header is shifted over 1 
#precip is RRR in reliable prognosis, but here it is in the Td column
Precip1 <- datAD$Td

#no convert precip to numbers
#calling trace precipitation 0.01
#precip is in mm
PrecipF1 <- ifelse(Precip1 == "Trace of precipitation" ,"0.01" ,
			ifelse(Precip1 == "No precipitation", "0",
				ifelse(Precip1 == "",0 ,Precip1)))
				
PrecipN1<-as.numeric(PrecipF1)



#now turn into a dataframe
PrecipDat <- data.frame(doy=yday(dateAP),year=year(dateAP),
						Precip=PrecipN1)
						

#now summarize across days

PrecipDay <- aggregate(PrecipDat$Precip, 
				by=list(PrecipDat$doy,PrecipDat$year), FUN="sum")
colnames(PrecipDay)<-c("doy","year","Pr.mm")				

#join D to dataframes
mEl.H$D<-datHtkg$D
mEl.L$D<-datLtkg$D
mEl.H17$D<-datHtkg17$D
mEl.L17$D<-datLtkg17$D

mgc.L$D<-datLtkg$D
mgc.H$D<-datHtkg$D
mgc.L17$D<-datLtkg17$D
mgc.H17$D<-datHtkg17$D

#join Precipitation with measurements 
Hgc<-join(mgc.H, PrecipDay, by=c("doy","year"), type="left")
Lgc<-join(mgc.L, PrecipDay, by=c("doy","year"), type="left")
Hgc17<-join(mgc.H17, PrecipDay, by=c("doy","year"), type="left")
Lgc17<-join(mgc.L17, PrecipDay, by=c("doy","year"), type="left")

HEl<-join(mEl.H,PrecipDay, by=c("doy","year"), type="left")
LEl<-join(mEl.L,PrecipDay, by=c("doy","year"), type="left")
HEl17<-join(mEl.H17,PrecipDay, by=c("doy","year"), type="left")
LEl17<-join(mEl.L17,PrecipDay, by=c("doy","year"), type="left")

#exclude precip days over 1mm 
Hgc$gc<-ifelse(Hgc$Pr.mm>1,NA,Hgc$gc)
Lgc$gc<-ifelse(Lgc$Pr.mm>1,NA,Lgc$gc)
Hgc17$gc<-ifelse(Hgc17$Pr.mm>1,NA,Hgc17$gc)
Lgc17$gc<-ifelse(Lgc17$Pr.mm>1,NA,Lgc17$gc)

HEl$El<-ifelse(HEl$Pr.mm>1,NA, HEl$El)
LEl$El<-ifelse(LEl$Pr.mm>1,NA, LEl$El)
HEl17$El<-ifelse(HEl17$Pr.mm>1,NA, HEl17$El)
LEl17$El<-ifelse(LEl17$Pr.mm>1,NA, LEl17$El)

##### end filter  ######################

###############################################################################
###############################################################################
############ Calculate daily T from ###########################################
############ average across sensors ###########################################
###############################################################################

###need to do this across each sensor to get the average daily T
##use El.H, El.L, El.H17, El.L17

#turn into a data frame 

HEl.all <- data.frame(doy=rep(El.H$doy, times=8),year=rep(El.H$year, times=8),
			hour=rep(timeDH,times=8),
			sensor=rep(seq(1,8),each=dim(El.H)[1])	, 
			T=as.vector(data.matrix(El.H[,3:10])))
LEl.all <- data.frame(doy=rep(El.L$doy, times=16),year=rep(El.L$year, times=16),
				hour=rep(timeDL,times=16),
				sensor=rep(seq(1,16),each=dim(El.L)[1])	,
				T=as.vector(data.matrix(El.L[,3:18])))

LEl.all17 <- data.frame(doy=rep(El.L17$doy, times=16),year=rep(El.L17$year, times=16),
				hour=rep(timeDL17,times=16),
				sensor=rep(seq(1,16),each=dim(El.L17)[1])	, 
				T=as.vector(data.matrix(El.L17[,3:18])))

HEl.all17 <- data.frame(doy=rep(El.H17$doy, times=16),year=rep(El.H17$year, times=16),
				hour=rep(timeDH17,times=16),
				sensor=rep(seq(1,16),each=dim(El.H17)[1])	, 
				T=as.vector(data.matrix(El.H17[,3:18])))					
				
				
#find number of observations 
HEl.nn<-na.omit(HEl.all)
LEl.nn<-na.omit(LEl.all)
HEl17.nn<-na.omit(HEl.all17)
LEl17.nn<-na.omit(LEl.all17)


#number for each
lengHEl<-aggregate(HEl.nn$T,by=list(HEl.nn$doy,HEl.nn$year, HEl.nn$sensor), FUN="length")
lengLEl<-aggregate(LEl.nn$T,by=list(LEl.nn$doy,LEl.nn$year, LEl.nn$sensor), FUN="length")
lengHEl17<-aggregate(HEl17.nn$T,by=list(HEl17.nn$doy,HEl17.nn$year, HEl17.nn$sensor), FUN="length")
lengLEl17<-aggregate(LEl17.nn$T,by=list(LEl17.nn$doy,LEl17.nn$year, LEl17.nn$sensor), FUN="length")

#grab only the days that have the full measurements
dayuseH<-data.frame(doy=lengHEl$Group.1[lengHEl$x==48],sensor=lengHEl$Group.3[lengHEl$x==48])
dayuseL<-data.frame(doy=lengLEl$Group.1[lengLEl$x==48],sensor=lengLEl$Group.3[lengLEl$x==48])
dayuseH17<-data.frame(doy=lengHEl17$Group.1[lengHEl17$x==48],sensor=lengHEl17$Group.3[lengHEl17$x==48])
dayuseL17<-data.frame(doy=lengLEl17$Group.1[lengLEl17$x==48],sensor=lengLEl17$Group.3[lengLEl17$x==48])


#El is in g m-2 s-1 need to convert to g per m2 half hour

HEl.nn$Ehh <- HEl.nn$T*60*30
HEl17.nn$Ehh <- HEl17.nn$T*60*30
LEl.nn$Ehh <- LEl.nn$T*60*30
LEl17.nn$Ehh <- LEl17.nn$T*60*30

HTuse <- join(HEl.nn,dayuseH, by=c("doy","sensor"),type="inner")
HTuse17 <- join(HEl17.nn,dayuseH17, by=c("doy","sensor"),type="inner")
LTuse <- join(LEl.nn,dayuseL, by=c("doy","sensor"),type="inner")
LTuse17 <- join(LEl17.nn,dayuseL17, by=c("doy","sensor"),type="inner")



#calculate T for each day
#need to reformat because trapz doesn't
#allow fro subsetting within it
#make a matrix out of each day to use

HTx<- matrix(rep(NA,dim(dayuseH)[1]*48), ncol=dim(dayuseH)[1])
HTy<- matrix(rep(NA,dim(dayuseH)[1]*48), ncol=dim(dayuseH)[1])
HTday<-numeric(0)
for(i in 1:dim(dayuseH)[1]){
	HTx[,i] <- HTuse$hour[HTuse$doy==dayuseH$doy[i]&HTuse$sensor==dayuseH$sensor[i]]
	HTy[,i] <- HTuse$Ehh[HTuse$doy==dayuseH$doy[i]&HTuse$sensor==dayuseH$sensor[i]]
	HTday[i]<-trapz(HTx[,i],HTy[,i])
}

#make a matrix out of each day to use
HTx17<- matrix(rep(NA,dim(dayuseH17)[1]*48), ncol=dim(dayuseH17)[1])
HTy17<- matrix(rep(NA,dim(dayuseH17)[1]*48), ncol=dim(dayuseH17)[1])
HTday17<-numeric(0)
for(i in 1:dim(dayuseH17)[1]){
	HTx17[,i] <- HTuse17$hour[HTuse17$doy==dayuseH17$doy[i]&HTuse17$sensor==dayuseH17$sensor[i]]
	HTy17[,i] <- HTuse17$Ehh[HTuse17$doy==dayuseH17$doy[i]&HTuse17$sensor==dayuseH17$sensor[i]]
	HTday17[i]<-trapz(HTx17[,i],HTy17[,i])
}

#low density
LTx<- matrix(rep(NA,dim(dayuseL)[1]*48), ncol=dim(dayuseL)[1])
LTy<- matrix(rep(NA,dim(dayuseL)[1]*48), ncol=dim(dayuseL)[1])
LTday<-numeric(0)
for(i in 1:dim(dayuseL)[1]){
	LTx[,i] <- LTuse$hour[LTuse$doy==dayuseL$doy[i]&LTuse$sensor==dayuseL$sensor[i]]
	LTy[,i] <- LTuse$Ehh[LTuse$doy==dayuseL$doy[i]&LTuse$sensor==dayuseL$sensor[i]]
	LTday[i]<-trapz(LTx[,i],LTy[,i])
}
#low density17
LTx17<- matrix(rep(NA,dim(dayuseL17)[1]*48), ncol=dim(dayuseL17)[1])
LTy17<- matrix(rep(NA,dim(dayuseL17)[1]*48), ncol=dim(dayuseL17)[1])
LTday17<-numeric(0)
for(i in 1:dim(dayuseL17)[1]){
	LTx17[,i] <- LTuse17$hour[LTuse17$doy==dayuseL17$doy[i]&LTuse17$sensor==dayuseL17$sensor[i]]
	LTy17[,i] <- LTuse17$Ehh[LTuse17$doy==dayuseL17$doy[i]&LTuse17$sensor==dayuseL17$sensor[i]]
	LTday17[i]<-trapz(LTx17[,i],LTy17[,i])
}
	#add to data frame
	
	dayuseL17$Tg<-LTday17
	dayuseL$Tg<-LTday
	dayuseH17$Tg<-HTday17
	dayuseH$Tg<-HTday
#convert to L
	#1 g is cm3 which is 1 mL so (1/1000) to be L
	dayuseL17$TL<-dayuseL17$Tg/1000
	dayuseH17$TL<-dayuseH17$Tg/1000
	dayuseL$TL<-dayuseL$Tg/1000
	dayuseH$TL<-dayuseH$Tg/1000
	
#aggregate sensors to get standard error and mean
#high density
	HTdayL<-aggregate(dayuseH$TL, by=list(dayuseH$doy),FUN="mean")
	HTdayLeng<-aggregate(dayuseH$TL, by=list(dayuseH$doy),FUN="length")
	HTdayLsd<-aggregate(dayuseH$TL, by=list(dayuseH$doy),FUN="sd")
	colnames(HTdayL)<-c("doy","TL.high")
	HTdayL$se.high<-HTdayLsd$x/sqrt(HTdayLeng$x)
	#exclude days with less than 3 sensors
	HTdayL<-HTdayL[HTdayLeng$x>2,]
	
	HTdayL17<-aggregate(dayuseH17$TL, by=list(dayuseH17$doy),FUN="mean")
	HTdayLeng17<-aggregate(dayuseH17$TL, by=list(dayuseH17$doy),FUN="length")
	HTdayLsd17<-aggregate(dayuseH17$TL, by=list(dayuseH17$doy),FUN="sd")
	colnames(HTdayL17)<-c("doy","TL.high")
	HTdayL17$se.high<-HTdayLsd17$x/sqrt(HTdayLeng17$x)
	#exclude days with less than 3 sensors
	HTdayL17<-HTdayL17[HTdayLeng17$x>2,]
#low density
	LTdayL<-aggregate(dayuseL$TL, by=list(dayuseL$doy),FUN="mean")
	LTdayLeng<-aggregate(dayuseL$TL, by=list(dayuseL$doy),FUN="length")
	LTdayLsd<-aggregate(dayuseL$TL, by=list(dayuseL$doy),FUN="sd")
	colnames(LTdayL)<-c("doy","TL.low")
	LTdayL$se.low<-LTdayLsd$x/sqrt(LTdayLeng$x)
	#exclude days with less than 3 sensors
	LTdayL<-LTdayL[LTdayLeng$x>2,]
	
	LTdayL17<-aggregate(dayuseL17$TL, by=list(dayuseL17$doy),FUN="mean")
	LTdayLeng17<-aggregate(dayuseL17$TL, by=list(dayuseL17$doy),FUN="length")
	LTdayLsd17<-aggregate(dayuseL17$TL, by=list(dayuseL17$doy),FUN="sd")
	colnames(LTdayL17)<-c("doy","TL.low")
	LTdayL17$se.low<-LTdayLsd17$x/sqrt(LTdayLeng17$x)
	#exclude days with less than 3 sensors
	LTdayL17<-LTdayL17[LTdayLeng17$x>2,]	
###############################################################################
###############################################################################
############ seperate met calc for plot########################################
###############################################################################
datLmet$e.sat<-0.611*exp((17.502*datLmet$Temp)/(datLmet$Temp+240.97))
datHmet$e.sat<-0.611*exp((17.502*datHmet$Ctemp)/(datHmet$Ctemp+240.97))

#calculate vapor pressure deficit
#here rh is is in decimal form 
datLmet$RHfix<-ifelse(datLmet$RH>=1,.999,datLmet$RH)
datHmet$RHfix<-ifelse(datHmet$RH>=1,.999,datHmet$RH)

datLmet$D<-(datLmet$e.sat-(datLmet$RHfix*datLmet$e.sat))
datHmet$D<-(datHmet$e.sat-(datHmet$RHfix*datHmet$e.sat))

###############################################################################
###############################################################################
############ Plots for comparision ############################################
###############################################################################

#############################
#####plot of daily met ######
##### El and gc        ######
##### daysummary       ######
#############################
#make a decimal day observation
datLmet$DD<-datLmet$doy+(datLmet$hour/24)
datHmet$DD<-datHmet$doy+(datHmet$hour/24)

Hgc$DD<-Hgc$doy+ (Hgc$hour/24)
Lgc$DD<-Lgc$doy+ (Lgc$hour/24)
Hgc17$DD<-Hgc17$doy+ (Hgc17$hour/24)
Lgc17$DD<-Lgc17$doy+ (Lgc17$hour/24)

HEl$DD<-HEl$doy + (HEl$hour/24)
LEl$DD<-LEl$doy + (LEl$hour/24)

HEl17$DD<-HEl17$doy + (HEl17$hour/24)
LEl17$DD<-LEl17$doy + (LEl17$hour/24)

#subset met to just be in 2016 summer
metL16<-datLmet[datLmet$doy>=180&datLmet$year==2016&datLmet$doy<=245,]
metH16<-datHmet[datHmet$doy>=180&datHmet$year==2016&datHmet$doy<=245,]

Precip16<-PrecipDay[PrecipDay$doy>=180&PrecipDay$year==2016&PrecipDay$doy<=245,]

metL17<-datLmet[datLmet$doy>=158&datLmet$year==2017&datLmet$doy<=198,]
metH17<-datHmet[datHmet$doy>=158&datHmet$year==2017&datHmet$doy<=198,]

Precip17<-PrecipDay[PrecipDay$doy>=158&PrecipDay$year==2017&PrecipDay$doy<=198,]

############################################################
#focus on making small single or double plots for comparision
# Compare air temperature and D in high vs low density

wd<-25
ld<-15

jpeg("c:\\Users\\hkropp\\Google Drive\\Viper_SF\\analysis_plot\\metcomp.jpg", width=1700,height=1700)	
	a<-layout(matrix(seq(1,6), nrow=3, byrow=TRUE), width=rep(lcm(wd),6), height=rep(lcm(ld),6))
	layout.show(a)
	#plot D and precip for 2016
	par(mai=c(0,0,0,0))
	plot(c(0,1),c(0,1), type="n", xlim=c(180,245), ylim=c(0,3), xlab=" ",
			ylab=" ", xaxs="i", yaxs="i", axes=FALSE)
	points(metL16$DD, metL16$D, type="l", col="deepskyblue3",lwd=2)
	points(metH16$DD, metH16$D, type="l", col="forestgreen",lwd=2)
	legend(180,3,c("low density", "high density"), 
			col=c("deepskyblue3","forestgreen"), lwd=2, cex=2, bty="n")
	axis(2, seq(0,3), cex.axis=3, las=2)
	mtext("VPD (KPa) 2016", side=2, line=7, cex=2)
	box(which="plot")
	
	par(mai=c(0,0,0,0))
	plot(c(0,1),c(0,1), type="n", xlim=c(158,200), ylim=c(0,3), xlab=" ",
			ylab=" ", xaxs="i", yaxs="i", axes=FALSE)
	points(metL17$DD, metL17$D, type="l", col="deepskyblue3",lwd=2)
	points(metH17$DD, metH17$D, type="l", col="forestgreen",lwd=2)
	mtext("VPD (KPa) 2017", side=4, line=7, cex=2)
	axis(4, seq(0,3), cex.axis=3, las=2)
	box(which="plot")
	
	par(mai=c(0,0,0,0))
	plot(c(0,1),c(0,1), type="n", xlim=c(180,245), ylim=c(0,30), xlab=" ",
			ylab=" ", xaxs="i", yaxs="i", axes=FALSE)
	points(metL16$DD, metL16$Temp, type="l", col="deepskyblue3",lwd=2)
	points(metH16$DD, metH16$Ctemp, type="l", col="forestgreen",lwd=2)	
	axis(2, seq(0,25, by=5),cex.axis=3, las=2)
	mtext("Air temp 2016", side=2, line=7, cex=2)
	box(which="plot")
	
	par(mai=c(0,0,0,0))
	plot(c(0,1),c(0,1), type="n", xlim=c(158,200), ylim=c(0,30), xlab=" ",
			ylab=" ", xaxs="i", yaxs="i", axes=FALSE)
	points(metL17$DD, metL17$Temp, type="l", col="deepskyblue3",lwd=2)
	points(metH17$DD, metH17$Ctemp, type="l", col="forestgreen",lwd=2)				
	axis(4, seq(0,25, by=5),cex.axis=3, las=2)
	mtext("Air temp 2017", side=4, line=7, cex=2)
	box(which="plot")
	
	par(mai=c(0,0,0,0))
	plot(c(0,1),c(0,1), type="n", xlim=c(180,245), ylim=c(0,35), xlab=" ",
			ylab=" ", xaxs="i", yaxs="i", axes=FALSE)
	for(i in 1:dim(Precip16)[1]){
		polygon(c(Precip16$doy[i]-.5,Precip16$doy[i]-.5,Precip16$doy[i]+.5,Precip16$doy[i]+.5),
				c(0,Precip16$Pr.mm[i],Precip16$Pr.mm[i],0), col="deepskyblue4", border=NA)
	}	
	axis(2, seq(0,30, by=5),cex.axis=3, las=2)
	mtext("Precip (mm) 2017", side=2, line=7, cex=2)
	axis(1, seq(180,240, by=5),cex.axis=3, lwd.ticks=2)
		mtext("Day of year", side=1, cex=2, line=4)
	box(which="plot")
	
	par(mai=c(0,0,0,0))
	plot(c(0,1),c(0,1), type="n", xlim=c(158,200), ylim=c(0,35), xlab=" ",
			ylab=" ", xaxs="i", yaxs="i", axes=FALSE)
	for(i in 1:dim(Precip17)[1]){
		polygon(c(Precip17$doy[i]-.5,Precip17$doy[i]-.5,Precip17$doy[i]+.5,Precip17$doy[i]+.5),
				c(0,Precip17$Pr.mm[i],Precip17$Pr.mm[i],0), col="deepskyblue4", border=NA)
	}	
	axis(4, seq(0,30, by=5),cex.axis=2, las=2)
	mtext("Precip (mm) 2017", side=4, line=7, cex=2)	
		axis(1, seq(160,200, by=5),cex.axis=3, lwd.ticks=2)
		mtext("Day of year", line=4, side=1, cex=2)		
	box(which="plot")

dev.off()


############################################################
# Compare El and gc in high vs low density


wd<-30
ld<-15

jpeg("c:\\Users\\hkropp\\Google Drive\\Viper_SF\\analysis_plot\\Tcomp.jpg", width=2200,height=2000)	
	a<-layout(matrix(seq(1,4), nrow=2, byrow=TRUE), width=rep(lcm(wd),4), height=rep(lcm(ld),4))
	layout.show(a)

	par(mai=c(0,0,0,0))
	plot(c(0,1),c(0,1), type="n", xlim=c(180,245), ylim=c(0,0.04), xlab=" ",
			ylab=" ", xaxs="i", yaxs="i", axes=FALSE)
	points(HEl$DD, HEl$El, type="b", pch=19, col="forestgreen",cex=2)		
	points(LEl$DD, LEl$El, type="b", pch=19, col="deepskyblue4",cex=2)	
	axis(2,seq(0,.04,by=.01),las=2,cex.axis=2)
	mtext("Transpiration", side=2, line=8, cex=2)
	box(which="plot")
	
	
	par(mai=c(0,0,0,0))
	plot(c(0,1),c(0,1), type="n", xlim=c(158,200), ylim=c(0,0.03), xlab=" ",
		ylab=" ", xaxs="i", yaxs="i", axes=FALSE)
	points(HEl17$DD, HEl17$El, type="b", pch=19, col="forestgreen",cex=2)		
	points(LEl17$DD, LEl17$El, type="b", pch=19, col="deepskyblue4",cex=2)	
	axis(4,seq(0,.03,by=.01),las=2,cex.axis=2)
	mtext("Transpiration", side=4, line=8, cex=2)	
	box(which="plot")	
	
	par(mai=c(0,0,0,0))
	plot(c(0,1),c(0,1), type="n", xlim=c(180,245), ylim=c(0,250), xlab=" ",
			ylab=" ", xaxs="i", yaxs="i", axes=FALSE)
	points(Hgc$DD, Hgc$gc, type="b", pch=19, col="forestgreen",cex=2)		
	points(Lgc$DD, Lgc$gc, type="b", pch=19, col="deepskyblue4",cex=2)		
	axis(2,seq(0,240,by=20),las=2,cex.axis=2)
	mtext("gc", side=2, line=8, cex=2)		
	box(which="plot")
	
	
	par(mai=c(0,0,0,0))
	plot(c(0,1),c(0,1), type="n", xlim=c(158,200), ylim=c(0,250), xlab=" ",
		ylab=" ", xaxs="i", yaxs="i", axes=FALSE)
	points(Hgc17$DD, Hgc17$gc, type="b", pch=19, col="forestgreen",cex=2)		
	points(Lgc17$DD, Lgc17$gc, type="b", pch=19, col="deepskyblue4",cex=2)
	axis(4,seq(0,240,by=20),las=2,cex.axis=2)
	mtext("gc", side=4, line=8, cex=2)
	box(which="plot")
dev.off()


###############################################################
######plot gc vs D

plot(log(Hgc$D),Hgc$gc, pch=19, col="forestgreen", ylab="gc", xlab="D" )	
points(log(Lgc$D),Lgc$gc, pch=19, col="deepskyblue4" )

plot(Hgc17$D,Hgc17$gc, pch=19, col="forestgreen", ylab="gc", xlab="D" )	
points(Lgc17$D,Lgc17$gc, pch=19, col="deepskyblue4" )
logDL<-log(Lgc$D)
orL<-lm(Lgc$gc~logDL)
summary(orL)
logDH<-log(Hgc$D)
orH<-lm(Hgc$gc~logDH)
summary(orH)
logDL17<-log(Lgc17$D)
orL17<-lm(Lgc17$gc~logDL17)
summary(orL17)
logDH17<-log(Hgc17$D)
orH17<-lm(Hgc17$gc~logDH17)
summary(orH17)


summary(orL)
plot(HEl$D,HEl$El, pch=19, col="forestgreen", ylab="gc", xlab="D" )	
points(LEl$D,LEl$El, pch=19, col="deepskyblue4" )

plot(HEl17$D,HEl17$El, pch=19, col="forestgreen", ylab="gc", xlab="D" )	
points(LEl17$D,LEl17$El, pch=19, col="deepskyblue4" )





##############################################################
######make a plot of daily transpiration across the with each stand overlayed
##############################################################
#start by organizing into same data frame by joining for each year

T2016<-join(LTdayL,HTdayL,by="doy",type="full")
T2017<-join(LTdayL17,HTdayL17,by="doy",type="full")
#turn na to zero for sake of plotting
T2016$TL.low<-ifelse(is.na(T2016$TL.low),0,T2016$TL.low)
T2016$TL.high<-ifelse(is.na(T2016$TL.high),0,T2016$TL.high)
T2016$se.low<-ifelse(is.na(T2016$se.low),0,T2016$se.low)
T2016$se.high<-ifelse(is.na(T2016$se.high),0,T2016$se.high)

T2017$TL.low<-ifelse(is.na(T2017$TL.low),0,T2017$TL.low)
T2017$TL.high<-ifelse(is.na(T2017$TL.high),0,T2017$TL.high)
T2017$se.low<-ifelse(is.na(T2017$se.low),0,T2017$se.low)
T2017$se.high<-ifelse(is.na(T2017$se.high),0,T2017$se.high)


#make a column for order of polygon
T2016$p1<-ifelse(T2016$TL.low>T2016$TL.high,T2016$TL.low,T2016$TL.high)
T2016$p2<-ifelse(T2016$TL.low<T2016$TL.high,T2016$TL.low,T2016$TL.high)
#cols
T2016$p1c<-ifelse(T2016$TL.low>T2016$TL.high,"dodgerblue3","palegreen4")
T2016$p2c<-ifelse(T2016$TL.low<T2016$TL.high,"dodgerblue3","palegreen4")
#make a column for order of polygon
T2017$p1<-ifelse(T2017$TL.low>T2017$TL.high,T2017$TL.low,T2017$TL.high)
T2017$p2<-ifelse(T2017$TL.low<T2017$TL.high,T2017$TL.low,T2017$TL.high)
#cols
T2017$p1c<-ifelse(T2017$TL.low>T2017$TL.high,"dodgerblue3","palegreen4")
T2017$p2c<-ifelse(T2017$TL.low<T2017$TL.high,"dodgerblue3","palegreen4")



ds16<-182
de16<-242
ds17<-159
de17<-197
ys<- 0
ye <- .5

wd<-30
ld<-30

jpeg("c:\\Users\\hkropp\\Google Drive\\Viper_SF\\analysis_plot\\dailyTc.jpg", width=2200,height=2000)	
	a<-layout(matrix(seq(1,2), nrow=1, byrow=FALSE), width=rep(lcm(wd),2), height=rep(lcm(ld),2))
	layout.show(a)
#2016 
par(mai=c(0,0,0,0))
plot(c(0,1),c(0,1), xlim=c(ds16,de16),ylim=c(ys,ye), xlab=" ", ylab=" ",
		axes=FALSE, xaxs="i", yaxs="i")
for(i in 1:dim(T2016)[1]){
polygon(c(T2016$doy[i]-.5,T2016$doy[i]-.5,T2016$doy[i],T2016$doy[i]),
		c(0,T2016$TL.low[i],T2016$TL.low[i],0), col="royalblue1")
polygon(c(T2016$doy[i],T2016$doy[i],T2016$doy[i]+.5,T2016$doy[i]+.5),
		c(0,T2016$TL.high[i],T2016$TL.high[i],0), col="palegreen4")
}

		
box(which="plot")

par(mai=c(0,0,0,0))
plot(c(0,1),c(0,1), xlim=c(ds17,de17),ylim=c(ys,ye), xlab=" ", ylab=" ",
		axes=FALSE, xaxs="i", yaxs="i")
for(i in 1:dim(T2017)[1]){
polygon(c(T2017$doy[i]-.5,T2017$doy[i]-.5,T2017$doy[i],T2017$doy[i]),
		c(0,T2017$TL.low[i],T2017$TL.low[i],0), col="royalblue1")
polygon(c(T2017$doy[i],T2017$doy[i],T2017$doy[i]+.5,T2017$doy[i]+.5),
		c(0,T2017$TL.high[i],T2017$TL.high[i],0), col="palegreen4")
}		
box(which="plot")

dev.off()



#######################################################################
######make plot of stomatal conductance
######first compare average daily gc across the sites

#aggregate the stomatal conductance
mgc.Ln<-na.omit(mgc.L)
dgc.L<-aggregate(mgc.Ln$gc,by=list(mgc.Ln$doy), FUN="mean")
colnames(dgc.L)<-c("doy","gc")

mgc.L17n<-na.omit(mgc.L17)
dgc.L17<-aggregate(mgc.L17n$gc,by=list(mgc.L17n$doy), FUN="mean")
colnames(dgc.L17)<-c("doy","gc")

mgc.Hn<-na.omit(mgc.H)
dgc.H<-aggregate(mgc.Hn$gc,by=list(mgc.Hn$doy), FUN="mean")
colnames(dgc.H)<-c("doy","gc")

mgc.H17n<-na.omit(mgc.H17)
dgc.H17<-aggregate(mgc.H17n$gc,by=list(mgc.H17n$doy), FUN="mean")
colnames(dgc.H17)<-c("doy","gc")

#get the average D across all of the days
DdayL16<-aggregate(metL16$D, by=list(metL16$doy,metL16$year),FUN="mean")
DdayH16<-aggregate(metH16$D, by=list(metH16$doy,metH16$year),FUN="mean")
DdayL17<-aggregate(metL17$D, by=list(metL17$doy,metL17$year),FUN="mean")
DdayH17<-aggregate(metH17$D, by=list(metH17$doy,metH17$year),FUN="mean")
colnames(DdayL16)<-c("doy","year","D")
colnames(DdayH16)<-c("doy","year","D")
colnames(DdayL17)<-c("doy","year","D")
colnames(DdayH17)<-c("doy","year","D")


ds16<-181
de16<-245
ds17<-157
de17<-200
ys<- 0
ye <-200
ysD<- 0
yeD <-1.6

wd<-20
ld<-12

tot16<-de16-ds16
tot17<-de17-ds17
totAll<-tot16+tot17

p16<-tot16/totAll
wd16<-round(p16*40)
wd17<-40-wd16	
	
a<-layout(matrix(seq(1,4), nrow=2, byrow=TRUE),
	 width=c(lcm(wd16),lcm(wd17),lcm(wd16),lcm(wd17)),
				height=c(lcm(ld),lcm(ld),lcm(ld),lcm(ld)))
	layout.show(a)
#2016 
par(mai=c(0,0,0,0))
plot(c(0,1),c(0,1), xlim=c(ds16,de16),ylim=c(ysD,yeD), xlab=" ", ylab=" ",
		axes=FALSE, xaxs="i", yaxs="i")
points(DdayL16$doy,DdayL16$D, type="l",lwd=5, col="royalblue1")	
points(DdayH16$doy,DdayH16$D, type="l",lwd=5, col="palegreen4",lty=3)	
axis(2, seq(0,2,by=.5), cex.axis=1.5,las=2)
mtext("Average vapor pressure deficit (KPa)", side=2, line=7, cex=1.5)	
box(which="plot")
mtext("2016", side=3, line=1, cex=2)
legend(181,1.6,c("low density","high density"), lwd=5, lty=c(1,2), col=c("royalblue1","palegreen4"),
		bty="n", cex=2)
#2017 
par(mai=c(0,0,0,0))
plot(c(0,1),c(0,1), xlim=c(ds17,de17),ylim=c(ysD,yeD), xlab=" ", ylab=" ",
		axes=FALSE, xaxs="i", yaxs="i")
points(DdayL17$doy,DdayL17$D, type="l",lwd=5, col="royalblue1")	
points(DdayH17$doy,DdayH17$D, type="l",lwd=5, col="palegreen4",lty=3)	
mtext("2017", side=3, line=1, cex=2)	
box(which="plot")

#2016 


par(mai=c(0,0,0,0))
plot(c(0,1),c(0,1), xlim=c(ds16,de16),ylim=c(ys,ye), xlab=" ", ylab=" ",
		axes=FALSE, xaxs="i", yaxs="i")
points(dgc.L$doy,dgc.L$gc,pch=19,type="b",col="royalblue1",cex=2)
points(dgc.H$doy,dgc.H$gc,pch=19,type="b",col="palegreen4",cex=2)
axis(1,seq(185,240,by=5),lwd.ticks=2,cex.axis=1.5)
axis(2,seq(0,175,by=25),lwd.ticks=2,cex.axis=1.5, las=2)
legend(183,200,c("low density","high density"), pch=19, lty=c(1,1), col=c("royalblue1","palegreen4"),
		bty="n", cex=2)
mtext("Average canopy stomatal conductance", side=2, line=7, cex=1.5)		
mtext(expression(paste("mmol m"^"-2"~"s"^"-1"~")")), side=2, line=4, cex=1.5)	
box(which="plot")

#2017
par(mai=c(0,0,0,0))
plot(c(0,1),c(0,1), xlim=c(ds17,de17),ylim=c(ys,ye), xlab=" ", ylab=" ",
		axes=FALSE, xaxs="i", yaxs="i")
points(dgc.L17$doy,dgc.L17$gc,pch=19,type="b",col="royalblue1",cex=2)
points(dgc.H17$doy,dgc.H17$gc,pch=19,type="b",col="palegreen4",cex=2)
axis(1,seq(160,200,by=5),lwd.ticks=2, cex.axis=1.5)
#axis(2,seq(0,350,by=50),lwd.ticks=2,cex=1.5)
box(which="plot")
mtext("Day of year", side=1, outer=TRUE, line=-1.5, cex=1.5)
#######################################################################
######make plot of El
######first compare average daily gc across the sites

#########################################################################
#####look at several time periods

##########################################################################
##########################################################################
######Water potential vs D and gc ########################################
##########################################################################
#look at past precipitation
PrecipPast<-rep(NA,dim(PrecipDay)[1])
for(i in 7:dim(PrecipDay)[1]){
	PrecipPast[i]<-(PrecipDay$Pr.mm[i]+PrecipDay$Pr.mm[i-1]+PrecipDay$Pr.mm[i-2]+
					PrecipDay$Pr.mm[i-3]+PrecipDay$Pr.mm[i-4]+PrecipDay$Pr.mm[i-5]
					+PrecipDay$Pr.mm[i-6])

}
PrecipDay$WeekP<-PrecipPast


#fix different site labelling
datwp$siteid<-ifelse(datwp$Site=="l"|datwp$Site=="ld","ld",
				ifelse(datwp$Site=="h"|datwp$Site=="hd","hd",NA))
#make a subsetted data frame of water potential
WPall<-data.frame(doy=datwp$DOY,year=datwp$Year,site=datwp$siteid,species=datwp$Species,
					wp=datwp$Water.potential,hour=datwp$hour,Time=datwp$hour+(datwp$minute/60)) 

			
#round the water potential time so that it can be matched to met/gc data
WPall$TimeM<-ifelse(WPall$Time-WPall$hour<=.25,WPall$hour,
				ifelse(WPall$Time-WPall$hour>.25&WPall$Time-WPall$hour<.75,(WPall$hour+.5),
				ifelse(WPall$Time-WPall$hour>=.75,WPall$hour+1,NA)))

#now match gc and D to the wp
#combine all into the same dataframe
Hgc$site<-rep("hd",dim(Hgc)[1])
Hgc17$site<-rep("hd",dim(Hgc17)[1])
Lgc$site<-rep("ld",dim(Lgc)[1])
Lgc17$site<-rep("ld",dim(Lgc17)[1])

#now combine all into the smae data frame
gcAll<-rbind(Hgc,Hgc17,Lgc,Lgc17)
colnames(gcAll)[3]<-"TimeM"
#take only larch
WPlarch<-WPall[WPall$species=="larix",]

#aggregate larch water potetnail across time period

#join 
WPLdat<-join(WPlarch,gcAll,by=c("site","doy","year", "TimeM"), type="left")

par(mfrow=c(1,2))


plot(WPLdat$D[WPLdat$site=="ld"&WPLdat$year==2016],WPLdat$wp[WPLdat$site=="ld"&WPLdat$year==2016],xlim=c(0,2.5), ylim=c(0.4,1.6),pch=19, col="royalblue1")
points(WPLdat$D[WPLdat$site=="ld"&WPLdat$year==2017],WPLdat$wp[WPLdat$site=="ld"&WPLdat$year==2017],pch=19, col="royalblue4")
points(WPLdat$D[WPLdat$site=="hd"&WPLdat$year==2016],WPLdat$wp[WPLdat$site=="hd"&WPLdat$year==2016],pch=19, col="palegreen2")
points(WPLdat$D[WPLdat$site=="hd"&WPLdat$year==2017],WPLdat$wp[WPLdat$site=="hd"&WPLdat$year==2017],pch=19, col="palegreen4")

#now look at mid day stress. Take all measurements occuring between 11:00-2:00pm
midSt<-WPLdat[WPLdat$hour>=11&WPLdat$hour<14,]
#now aggregate across stand and day
midStA<-aggregate(midSt$wp,by=list(midSt$doy,midSt$year,midSt$site),FUN="mean")
midStSD<-aggregate(midSt$wp,by=list(midSt$doy,midSt$year,midSt$site),FUN="sd")
midStL<-aggregate(midSt$wp,by=list(midSt$doy,midSt$year,midSt$site),FUN="length")
colnames(midStA)<-c("doy","year","site","wp")
colnames(midStSD)<-c("doy","year","site","wp.sd")
colnames(midStL)<-c("doy","year","site","wp.L")
midStSD$se<-midStSD$wp.sd/sqrt(midStL$wp.L)

midD<-aggregate(midSt$D,by=list(midSt$doy,midSt$year,midSt$site),FUN="mean")
colnames(midD)<-c("doy","year","site","midD")
midStA<-join(midStA,midD,by=c("doy","year","site"), type="left")

#join Precipday to mid
midStA<-join(midStA,PrecipDay,by=c("doy","year"), type="left")


plot(c(0,1),c(0,1), type="n",ylim=c(.5,1.6), xlim=c(169,245), xlab=" ", ylab=" ", xaxs="i",
		yaxs="i", axes=FALSE)
		
points(midStA$doy[midStA$site=="ld"],midStA$wp[midStA$site=="ld"], pch=19, col="royalblue1")		
points(midStA$doy[midStA$site=="hd"],midStA$wp[midStA$site=="hd"], pch=19, col="palegreen4")


arrows(midStA$doy[midStA$site=="ld"],
		midStA$wp[midStA$site=="ld"]-midStSD$se[midStSD$site=="ld"],
		midStA$doy[midStA$site=="ld"],
		midStA$wp[midStA$site=="ld"]+midStSD$se[midStSD$site=="ld"],
		code=0)

arrows(midStA$doy[midStA$site=="hd"],
		midStA$wp[midStA$site=="hd"]-midStSD$se[midStSD$site=="hd"],
		midStA$doy[midStA$site=="hd"],
		midStA$wp[midStA$site=="hd"]+midStSD$se[midStSD$site=="hd"],
		code=0)
		
gcnn<-na.omit(gcAll)
maxgc<-aggregate(gcnn$gc, by=list(gcnn$doy,gcnn$year, gcnn$site), FUN="mean")
colnames(maxgc)<-c("doy","year","site","mean.gc")
#now join to mid day
midStA<-join(midStA,maxgc,by=c("doy","year","site"), type="left")

plot(midStA$wp[midStA$site=="ld"],midStA$mean.gc[midStA$site=="ld"],pch=19, col="royalblue1")
points(midStA$wp[midStA$site=="hd"],midStA$mean.gc[midStA$site=="hd"],pch=19, col="palegreen4")

####################################################
#aggregate larch water potetnail across time period
WPL<-aggregate(WPlarch$wp, by=list(WPlarch$doy,WPlarch$year,WPlarch$site,WPlarch$TimeM), FUN="mean")
colnames(WPL)<-c("doy","year","site","TimeM","wp")
#now join to gc 
WPLd<-join(WPL,gcAll,by=c("doy","year","TimeM","site"), type="left")

wd<-15
hd<-15

#test relationships
DWH<-lm(WPLd$wp[WPLd$site=="hd"]~WPLd$D[WPLd$site=="hd"])
DWL<-lm(WPLd$wp[WPLd$site=="ld"]~WPLd$D[WPLd$site=="ld"])
GWH<-lm(WPLd$gc[WPLd$site=="hd"]~WPLd$wp[WPLd$site=="hd"])
GWL<-lm(WPLd$gc[WPLd$site=="ld"])~WPLd$wp[WPLd$site=="ld"])

summary(DWH)
summary(DWL)
summary(GWH)
summary(GWL)

ab<-layout(matrix(c(1,2), ncol=2), width=rep(lcm(wd),2),height=rep(lcm(hd),2))
layout.show(ab)
par(mai=c(0,0,0,0))
plot(c(0,1),c(0,1), type="n",ylim=c(.4,1.6), xlim=c(0,2.5), xlab=" ", ylab=" ", xaxs="i",
		yaxs="i", axes=FALSE)
points(WPLd$D[WPLd$site=="hd"],WPLd$wp[WPLd$site=="hd"], pch=19, col="palegreen4",cex=1.75)
points(WPLd$D[WPLd$site=="ld"],WPLd$wp[WPLd$site=="ld"], pch=19, col="royalblue1",cex=1.75)	
abline(DWH,col="palegreen4",lwd=2 )
abline(DWL,col="royalblue1",lwd=2 )
axis(2,seq(.4,1.6,by=.2), las=2,cex.axis=1.5)
axis(1,seq(0,2.5,by=.5), cex.axis=1.5)
box(which="plot")
mtext("Xylem water potential (- MPa)", side=2, cex=1.5, line=4)
mtext("Vapor pressure Deficit (KPa)", side=1, cex=1.5, line=3)
legend(0,1.6, c("low density", "high density"), col=c("royalblue1","palegreen4"), pch=19,
		cex=1.5, bty="n")
par(mai=c(0,0,0,0))
plot(c(0,1),c(0,1), type="n",ylim=c(0,80), xlim=c(.2,1.6), xlab=" ", ylab=" ", xaxs="i",
		yaxs="i", axes=FALSE)
points(WPLd$wp[WPLd$site=="hd"],WPLd$gc[WPLd$site=="hd"], pch=19, col="palegreen4",cex=1.75)
points(WPLd$wp[WPLd$site=="ld"],WPLd$gc[WPLd$site=="ld"], pch=19, col="royalblue1",cex=1.75)
abline(GWH,col="palegreen4",lwd=2 )
#abline(GWL,col="royalblue1",lwd=2 )			
box(which="plot")
axis(1,seq(.4,1.6,by=.2),cex.axis=1.5)
axis(4,seq(0,80,by=10), las=2,cex.axis=1.5)
mtext(expression(paste("Canopy stomatal conductance (mmol m"^"-2"~"s"^"-1"~" )")), side=4, cex=1.5, line=4)
mtext("Xylem water potential (- MPa)", side=1, cex=1.5, line=3)





#############################################################################
#######make panel with wp vs d and mid day stress
wd<-15
hd<-15




ab<-layout(matrix(seq(1,2), ncol=2), width=rep(lcm(wd),2),height=rep(lcm(hd),2))
layout.show(ab)
par(mai=c(0,0,0,0))
plot(c(0,1),c(0,1), type="n",ylim=c(.4,1.6), xlim=c(0,2.5), xlab=" ", ylab=" ", xaxs="i",
		yaxs="i", axes=FALSE)
points(WPLd$D[WPLd$site=="hd"],WPLd$wp[WPLd$site=="hd"], pch=19, col="palegreen4",cex=2)
points(WPLd$D[WPLd$site=="ld"],WPLd$wp[WPLd$site=="ld"], pch=19, col="royalblue1",cex=2)	
axis(2,seq(.4,1.6,by=.2), las=2,cex.axis=1.5)
axis(1,seq(0,2.5,by=.5), cex.axis=1.5)
box(which="plot")
mtext("Xylem water potential (- MPa)", side=2, cex=1.5, line=4)
mtext("Vapor pressure Deficit (KPa)", side=1, cex=1.5, line=3)
legend(0,1.6, c("low density", "high density"), col=c("royalblue1","palegreen4"), pch=19,
		cex=2, bty="n")


plot(c(0,1),c(0,1), type="n",ylim=c(.4,1.6), xlim=c(180,200), xlab=" ", ylab=" ", xaxs="i",
		yaxs="i", axes=FALSE)
		
points(midStA$doy[midStA$site=="ld"&midStA$year==2017],midStA$wp[midStA$site=="ld"&midStA$year==2017], pch=19, col="royalblue1", cex=2)		
points(midStA$doy[midStA$site=="hd"&midStA$year==2017],midStA$wp[midStA$site=="hd"&midStA$year==2017], pch=19, col="palegreen4", cex=2)


arrows(midStA$doy[midStA$site=="ld"&midStA$year==2017],
		midStA$wp[midStA$site=="ld"&midStA$year==2017]-midStSD$se[midStSD$site=="ld"&midStA$year==2017],
		midStA$doy[midStA$site=="ld"&midStA$year==2017],
		midStA$wp[midStA$site=="ld"&midStA$year==2017]+midStSD$se[midStSD$site=="ld"&midStA$year==2017],
		code=0)

arrows(midStA$doy[midStA$site=="hd"&midStA$year==2017],
		midStA$wp[midStA$site=="hd"&midStA$year==2017]-midStSD$se[midStSD$site=="hd"&midStA$year==2017],
		midStA$doy[midStA$site=="hd"&midStA$year==2017],
		midStA$wp[midStA$site=="hd"&midStA$year==2017]+midStSD$se[midStSD$site=="hd"&midStA$year==2017],
		code=0)
axis(1, seq(185,205,by=5), cex.axis=1.5)
mtext("Day of year 2017", side=1, cex=1.5, line=3)	
box(which="plot")	

axis(4,seq(.4,1.6,by=.2), las=2,cex.axis=1.5)
mtext("Mid-day Xylem water potential (- MPa)", side=4, cex=1.5, line=4)