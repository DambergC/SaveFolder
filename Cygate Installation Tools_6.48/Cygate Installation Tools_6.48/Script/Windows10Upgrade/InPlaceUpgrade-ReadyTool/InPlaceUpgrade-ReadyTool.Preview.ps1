#----------------------------------------------
# Generated Form Function
#----------------------------------------------
function Show-InPlaceUpgrade-ReadyTool_psf {

	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	#endregion Import Assemblies

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$InPlaceUpgradeReadyTool = New-Object 'System.Windows.Forms.Form'
	$buttonMinimize = New-Object 'System.Windows.Forms.Button'
	$labelDriverMessage = New-Object 'System.Windows.Forms.Label'
	$labelPowerConnected = New-Object 'System.Windows.Forms.Label'
	$picturebox1 = New-Object 'System.Windows.Forms.PictureBox'
	$labelWindowsUpgrade = New-Object 'System.Windows.Forms.Label'
	$textHeader = New-Object 'System.Windows.Forms.TextBox'
	$readyToolDeferLbl = New-Object 'System.Windows.Forms.Label'
	$readyToolInfoTb = New-Object 'System.Windows.Forms.TextBox'
	$readyToolStartbutton = New-Object 'System.Windows.Forms.Button'
	$readyToolPostponeButton = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$InPlaceUpgradeReadyTool.SuspendLayout()
	#
	# InPlaceUpgradeReadyTool
	#
	$InPlaceUpgradeReadyTool.Controls.Add($buttonMinimize)
	$InPlaceUpgradeReadyTool.Controls.Add($labelDriverMessage)
	$InPlaceUpgradeReadyTool.Controls.Add($labelPowerConnected)
	$InPlaceUpgradeReadyTool.Controls.Add($picturebox1)
	$InPlaceUpgradeReadyTool.Controls.Add($labelWindowsUpgrade)
	$InPlaceUpgradeReadyTool.Controls.Add($textHeader)
	$InPlaceUpgradeReadyTool.Controls.Add($readyToolDeferLbl)
	$InPlaceUpgradeReadyTool.Controls.Add($readyToolInfoTb)
	$InPlaceUpgradeReadyTool.Controls.Add($readyToolStartbutton)
	$InPlaceUpgradeReadyTool.Controls.Add($readyToolPostponeButton)
	$InPlaceUpgradeReadyTool.AutoScaleDimensions = '6, 13'
	$InPlaceUpgradeReadyTool.AutoScaleMode = 'Font'
	$InPlaceUpgradeReadyTool.BackColor = '250, 250, 250'
	$InPlaceUpgradeReadyTool.ClientSize = '515, 398'
	$InPlaceUpgradeReadyTool.FormBorderStyle = 'None'
	#region Binary Data
	$InPlaceUpgradeReadyTool.Icon = [System.Convert]::FromBase64String('
AAABAAQAEBAAAAEAIABoBAAARgAAACAgAAABACAAqBAAAK4EAAAwMAAAAQAgAKglAABWFQAAQEAA
AAEAIAAoQgAA/joAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAACUWAAAlFgAAAAAAAAAAAAD/////
//////////////////////v58//g0qf/xKdU/7iXM/+7mjv/y7Nq/+fcvP/8+/j/////////////
//////////////////////////Pt3P/Gq1r/qoIL/6Z8AP+mewD/pXsA/6Z8AP+thhL/zLNr//by
5f////////////////////////////Lr2f+7mz3/pnsA/6Z8AP+mfAD/q4MN/7GMHv+uiBb/p34E
/6V6AP/Bo0z/9vLm//////////////////j17P/Bo0z/pnsA/6Z8AP+qggz/ybBl/+rgxf/079//
8OnT/97Po/+7nD7/pnwB/862cv/+/fv///////7+/v/TvoD/p30C/6Z8AP+shRH/28qZ//z68v/y
46z/5stj/+XIWv/t2In/8efF/8WqW/+uiBj/6uDD///////s48n/r4kY/6Z8AP+ofwb/18SM//z5
7//nzWr/2KwH/9aoAP/VpwD/1qcA/9+6L//r3Kf/t5Yz/821cP/9/fv/ybBl/6Z7AP+mewD/wqVQ
//r37//q03z/16oD/9apAP/csx7/6Mti/+nLYP/cshn/4L07/9K7cv+7mzz/7eXN/7CKG/+mfAD/
q4MO/+jdvv/16sD/2a8S/9apAP/fujD/9OvI/87n/P+53fv/3d/C/9+5Lf/bwGX/upk7/9O+gf+n
fQL/pnsA/76fRP/69+3/5MZX/9aoAP/ZrxH/8+e5/63Z/v9CpPT/NJ3z/1+z+v/Qy43/3LtL/8Ci
TP+8nUD/pnwA/6Z8AP/Uv4T/+fHV/9qxF//WqAD/5sdX/9rs9/9LqPT/PqLz/43I+P9zvPr/nsC8
/9y7TP/KsWn/sIob/6Z8AP+ofgP/4tSt//Liqf/XqgL/16kA//Hdlf+k1P3/MZvz/33A9//+////
z+n//6LAtv/VtU3/3Mye/62GFP+mfAD/qYAF/+XauP/v3Zn/1qkA/9eqAP/y353/ndH+/y+b8/9z
u/f/yeX//6PQ8v/GwXz/0LRg//Tv4f+1kSr/pnwA/6d9AP/ZyJX/9eq//9itDP/WqAD/48NK/9/l
1/+Rxu3/fbzm/5vDy//HxIP/0LJN/+PWsP//////0bt7/6d9A/+mewD/uZg1//Dp0f/s1oT/3LUg
/9muDP/fuCf/5MRL/+PFVP/ev1H/z7FR/97OoP/9/Pr///////fz6P/HrF7/qYAH/6Z7AP+2ky3/
076A/93Jiv/cxHb/171k/9G1Wf/Krlb/zrZv/+jewP/+/fv/////////////////+ffv/93Nnv/C
pU//tJAn/6+JGv+zjyX/upk6/8KmVP/RvH//59y8//r48f//////////////////////AAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
ACgAAAAgAAAAQAAAAAEAIAAAAAAAABAAACUWAAAlFgAAAAAAAAAAAAD/////////////////////
////////////////////////////////////////////////+/n0/+zkyv/bypj/z7h2/822cv/P
t3X/2caS/+fcvP/28uf//v79////////////////////////////////////////////////////
////////////////////////////////////////////////////////+/jz/+HTqv/Bo07/r4gX
/6h/BP+mfAD/pnwA/6Z8AP+ofgP/rIQP/7eVMf/PuHb/7eXM//79+///////////////////////
/////////////////////////////////////////////////////////////////////+3lzP/C
pVD/qYAI/6V7AP+mfAD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/6Z7AP+uiBf/zrd0//Xw
4///////////////////////////////////////////////////////////////////////////
//7+/P/h0qn/so0i/6Z7AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6Z8AP+mfAH/upk5/+rhxP//////////////////////////////////////////////////
///////////////+/fz/28ua/6yFEv+mfAD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z8
AP+mfAD/pnwA/6d9AP+nfQD/p30A/6d9AP+mewD/so4j/+fbuv//////////////////////////
///////////////////////////////+/93Nnv+shBD/pnwA/6d9AP+nfQD/p30A/6d9AP+nfQD/
pnwA/6Z8AP+qggv/sYsd/7KNIf+viRn/qYEJ/6Z8AP+mewD/p30A/6d9AP+mewD/s48k/+vixv//
///////////////////////////////////////////////n27v/r4gZ/6Z8AP+nfQD/p30A/6d9
AP+nfQD/pnwA/6Z8Av+1kSr/0rx9/+jev//z7d3/9fDi//Hr2P/m27n/076B/7mYNv+ofwb/pnwA
/6d9AP+mewD/vZ5C//fz6f//////////////////////////////////////8uvZ/7eUMP+mewD/
p30A/6d9AP+nfQD/p30A/6Z8AP+shBD/z7h2//Tv4P//////////////////////////////////
////+PXs/9vKmP+zjyX/pnwA/6d9AP+nfQL/1MCF//////////////////////////////////z6
9f/HrF//pnsA/6d9AP+nfQD/p30A/6d9AP+mfAD/sIse/+DSqP/+/fv////////////8+Ov/9Oi8
/+/dnP/u3Jj/8N+i//bsyv/9+/P//////+7m0P+8nD//pnwA/6Z8AP+yjiP/8uvZ////////////
////////////////3s6g/6mACf+nfQD/p30A/6d9AP+nfQD/pnwA/7GMH//m2rf////////////9
+vL/7tyZ/9+7Nv/YrQr/16oA/9epAP/XqgL/2a8R/+HARf/x4qv//v35//Ls2v+5mDb/pnwA/6Z8
AP/Vwoj///////////////////////Tv3/+2ky7/pnwA/6d9AP+nfQD/p30A/6Z8AP+shRH/4dOq
////////////+vXj/+XIXP/Xqwb/1qkA/9eqAP/XqgD/16oA/9eqAP/XqgD/1qkA/9itC//nzW3/
/Pnt/+nfwf+viRj/pXoA/7ycPv/59+//////////////////0rx9/6Z8AP+nfQD/p30A/6d9AP+n
fQD/qH4E/9TAhf/+/vz///////r15P/iwkr/1qkA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eq
AP/XqgD/16kA/9epAf/lyV///Pnw/9C6e/+mfAD/rYcV/+vhxv////////////Hq1v+xjCD/pnwA
/6d9AP+nfQD/p30A/6Z7AP+/oUn/+fbu///////9+/L/5clf/9apAP/XqgD/16oA/9eqAP/XqgD/
1qkA/9eqBP/Zrg7/2a4N/9eqAv/WqQD/16oA/9eqA//s1ob/8OnT/7CLHP+nfgL/2smX////////
////0bx9/6Z8AP+nfQD/p30A/6d9AP+mfAD/rIUS/+jdvf///////////+zYjP/XqwX/16oA/9eq
AP/XqgD/16oA/9eqBP/hv0P/796g//bsx//168X/7tyZ/+C+P//XqgT/1qkA/9uyHP/27Mv/xapb
/6V6AP/NtW////////Xw4/+1kSr/pnwA/6d9AP+nfQD/p30A/6Z7AP/IrmL//fz6///////37cz/
27Md/9epAP/XqgD/16oA/9epAP/YrAn/6dJ6//z57f///////v////3////+/////fns/+nQc//X
qwb/1qkA/+vTff/ZyJT/pnsA/8arXf//////3s+i/6h+BP+nfQD/p30A/6d9AP+nfAD/rIUQ/+nf
wf///////v35/+XIXv/WqQD/16oA/9eqAP/XqgD/16sG/+rUgP/+/fj//v7//9Do/P+Ixfj/dr33
/4nG+P/H5P3/+fr1/+fKY//WqAD/4L07/+TWq/+pgAf/w6ZT//38+f/EqFf/pXsA/6d9AP+nfQD/
p30A/6Z7AP/Aokr//Pr1///////16b//2a8Q/9epAP/XqgD/16oA/9apAP/kxlj//fvz//7///+z
2vr/SKf0/zKc8/8znPP/M5zz/z+i8/+Wzfv/8e3V/9yzHv/bshn/5taj/6yFEf/HrF7/8evZ/7KN
Iv+mfAD/p30A/6d9AP+nfQD/p30B/9rJlv///////v78/+bLZf/WqQD/16oA/9eqAP/XqQD/27Ic
//fuzf//////xeP7/0Wl9P80nfP/Np7z/zWe8/80nfP/M53z/zqg8/+12/n/6Mtj/9muDf/m1Zv/
rogX/821cP/g0ab/qYAI/6d9AP+nfQD/p30A/6Z8AP+uhxX/7ubP///////589v/27Qg/9epAP/X
qgD/16oA/9apAP/oznH////+/+z2/v9is/X/M5zz/zae8/81nfP/PqLz/1yw9f9LqPT/Mpzz/2+6
+v/n2JX/2q8Q/+PQkv+uhxf/2smW/822cP+mfAD/p30A/6d9AP+nfQD/pnsA/7mYNv/59+//////
//Dgo//XqgP/16oA/9eqAP/XqgD/2a4P//Xqwv//////q9b6/zee8/82nvP/NZ3z/0al9P+02/r/
8vn+/9rt/f9ltPb/T6v4/9rXp//dsxr/3ciF/7CKHf/q4MP/v6BH/6Z8AP+nfQD/p30A/6d9AP+l
ewD/xapZ//7+/f//////581t/9aoAP/XqgD/16oA/9apAP/eujP//Pnt//f7//9suPb/M5zz/zae
8/81nfP/l8z4//7//////////////7jc+/9RrPj/1c+W/+C6L//RuG//uZk5//j17f+2ky7/pnwA
/6d9AP+nfQD/p30A/6V7AP/OtnL///////78+P/iwUn/1qkA/9eqAP/XqgD/1qgA/+PEUv///vv/
4/L9/0yo9P81nfP/NZ3z/0Kk9P/U6vz/////////////////wuH7/2m29//cx2r/48RV/76fRv/R
u3v//////7WSKf+mfAD/p30A/6d9AP+nfQD/pnsA/9S/g////////fry/9+8Of/WqQD/16oA/9eq
AP/WqAD/5MdY/////f/c7v3/RqX0/zWd8/81nfP/RqX0/9vt/f///////////+/3/v9/wfn/nsjc
/+G8Of/cxHL/tZIu/+7mzv//////tZIs/6Z8AP+nfQD/p30A/6d9AP+mewD/0Ll3///////9+/X/
4L4//9apAP/XqgD/16oA/9apAP/iwUj///33/+z2/v9YrvX/Mpzz/zae8/83n/P/e7/3/7Ta+v+d
z/n/ZrX3/3y/8//ayHH/4cFK/8OlTv/MtG7//v79//////+9nUH/pnwA/6d9AP+nfQD/p30A/6V7
AP/FqVj//v38/////v/mymX/1qgA/9eqAP/XqgD/16kA/9qwFv/16sP//////7jd+/9TrPX/O6Dz
/zae8/84n/P/RKX2/1+z+f+hzuz/3c2A/+C6Mv/St2P/uZg5//Pt3P///////////8+4dP+nfQD/
p30A/6d9AP+nfQD/pnwA/7SQKP/18OL///////LksP/YrAv/16kA/9eqAP/XqgD/1qkA/966NP/z
5rb//Prw/+Xy+//F4/z/stn4/73c8f/R4N3/49qm/+PBR//guzb/2L9u/7WSLf/j1rD/////////
////////6N2+/62GE/+nfAD/p30A/6d9AP+nfQD/p34C/9bDi////////vz3/+fObf/XqgT/1qkA
/9eqAP/XqgD/16kA/9muDv/fvDj/5sda/+rNaf/oyFn/478+/961IP/csxz/48Zc/9O7cP+1kiz/
3c2f//7+/v/////////////////8+/f/x6xf/6V7AP+nfQD/p30A/6d9AP+mfAD/r4kZ/+HTqv/+
/v3//fry/+zYjP/duCz/2KwI/9epAP/WqQD/1qgA/9anAP/WqAD/16oC/9qvEf/gvDb/5s1u/+HN
jP/DplH/tZMu/+HTqv/+/v3////////////////////////////w6dX/t5Uw/6V7AP+nfQD/p30A
/6d9AP+mfAD/rIUT/863dP/u59D/+/r2//v25v/06Lz/792Z/+vVgP/r1H3/6tN9/+zYj//s257/
6Nik/9rHjv/CpVH/sIsf/8OnVf/u59D////////////////////////////////////////////t
5c3/vZ5C/6d9A/+mewD/p3wA/6d9AP+mfAD/pnwB/66IFv+9nkP/yrJq/9XCiv/Zx5X/2ceU/9bD
jP/NtXH/xapb/7mYOf+uiBn/rYYU/8CiSv/j1a7/+/r1////////////////////////////////
///////////////////////49Or/2siV/7ycP/+thhP/qH4D/6Z8AP+mfAD/pnsA/6V6AP+kegD/
pXoA/6V7AP+lewD/pnwB/6mAB/+wihz/vp9E/9O+gv/r4sf/+/r1////////////////////////
////////////////////////////////////////////////////+fbu/+nfwv/YxpH/zLNs/8Kl
UP+8nD7/u5s9/7ubPf+9nkL/xapa/820b//XxI3/5Ney//Hq2P/7+fT/////////////////////
////////////////////////////////////////////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAoAAAAMAAAAGAA
AAABACAAAAAAAAAkAAAlFgAAJRYAAAAAAAAAAAAA////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/v79//n27v/w6NP/5dm1/+PWsf/j1rD/5Ney/+fcvP/y7dz/+vfx//7+/v//////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
//////////////////n38P/m2rn/zbZy/7uaPP+xix7/qoIM/6qBCv+qgQr/qoEK/6yEEP+yjiT/
vJ1A/821cf/j1a//9vLm///+/v//////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
///////////////////////////////////69/D/38+k/72dQv+qggv/pnsA/6Z7AP+mfAD/p30A
/6d9AP+nfQD/p30A/6d9AP+mfAD/pnsA/6Z7AP+pgAf/tpMt/9G8ff/w6dX//v79////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////v79/+rgwv/Aokz/qYAI/6V7
AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA
/6Z8Af+xjCD/076B//by5v//////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////7
+fT/2MWQ/6+JGf+lewD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+mfAD/pn0C/7ubPf/o3b3//v79////////////////
////////////////////////////////////////////////////////////////////////////
//////////////////////f06v/KsWn/qH8H/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z7
AP+viBn/28mX//38+f//////////////////////////////////////////////////////////
////////////////////////////////////////////9fHk/8SnVv+mfAL/p30A/6d9AP+nfQD/
p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+mfAD/qoIM/9TAhf/8+/j/////////////////////////
///////////////////////////////////////////////////////////////////28eX/wqZS
/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/
pnwA/6Z8AP+mfAD/pnwA/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/6mACv/W
won//fz6////////////////////////////////////////////////////////////////////
//////////////n27f/EqFf/pnwA/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A
/6d9AP+nfQD/pnsA/6Z8Af+pgQn/sIoc/7KNIv+yjSL/sIoc/6qCC/+nfQL/pXsA/6Z8AP+nfQD/
p30A/6d9AP+nfQD/p30A/6Z8AP+qggz/3Myb////////////////////////////////////////
/////////////////////////////////////fz5/8+3dv+nfQL/p30A/6d9AP+nfQD/p30A/6d9
AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z7AP+pgAj/upk5/9K9gP/m2rf/8uvZ//Xw4v/18OL/8uzZ
/+jdvv/byZf/xqxe/7KOI/+nfQP/pnwA/6d9AP+nfQD/p30A/6d9AP+mfAD/sYwf/+3kyv//////
////////////////////////////////////////////////////////////////28qa/6qBC/+n
fAD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+mfAD/p30E/7ubPv/g0ab/+PXt////
/////////////////////////////////////////v37//Pt3f/YxpL/t5Ux/6d9Av+mfAD/p30A
/6d9AP+nfQD/pnsA/8GkT//69/D/////////////////////////////////////////////////
///////////p3sD/r4kb/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z8AP+t
hhX/07+D//f06v//////////////////////////////////////////////////////////////
////////9fDj/9C6ev+shRP/pnwA/6d9AP+nfQD/p30A/6h/Bv/cy5v/////////////////////
//////////////////////////////////f06f+9nUH/pnsA/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6d9AP+nfQD/pnsA/7SQKP/k2LP//v78/////////////////////////////fz3//nz3v/4
8NX/9+/S//jw1f/5893//fv1//////////////////79+//j1a//s48l/6Z8AP+nfQD/p30A/6Z7
AP+4ljT/9vLm/////////////////////////////////////////////v79/9G7fP+nfQL/p30A
/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+mewD/uJY0/+zjyv//////////////////////
//7+//nz3f/t2ZH/4sJM/9u0Iv/asBb/2rAV/9qwFv/btCH/4cBH/+vVhf/379H//v37////////
////6uDD/7SRKv+mfAD/p30A/6d9AP+nfgT/28qZ////////////////////////////////////
////////6N2//66HFv+mfAD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z7AP+4ljT/7ubP
///////////////////////8+e//7dmQ/9y2KP/XqgL/1qkA/9epAP/XqQD/16oA/9epAP/XqQD/
1qkA/9apAf/ashr/6M5x//nz2////////////+bat/+viBj/pnwA/6d9AP+mewD/vZ5C//r48f//
///////////////////////////////69/D/wKJL/6V7AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+nfQD/pnwA/7GMIP/q4MT///////////////////////ny2f/jxVT/16oF/9apAP/XqgD/16oA
/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqQD/1qkB/924L//y5bP///79/////v/ayJX/
qYAI/6d9AP+nfQD/rIQP/+rgxP/////////////////////////////////dzJ3/qH8G/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+mfAD/q4MP/9/Rpf//////////////////////9+7O/9+7
OP/WqQD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA
/9apAP/asBf/796e///+/f/7+fT/w6dV/6Z7AP+nfQD/pnwA/9TAhv//////////////////////
//////bx5f+4ljT/pnsA/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQL/0bx9//79+///
///////////////48NT/3roz/9apAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eq
AP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/WqQD/2a8T//HirP//////6uDD/62GFP+mfAD/pXsA
/8GjTv/8+/f//////////////////////9jFj/+nfQL/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6Z7AP+8nED/9/Pp//////////////////v25//hwEj/1qkA/9eqAP/XqgD/16oA/9eqAP/X
qgD/16oA/9eqAP/XqgD/16oA/9apAP/WqAD/1qkA/9apAP/XqgD/16oA/9eqAP/XqgD/1qkA/9y1
Jf/37s7//f37/8WqW/+mewD/pnwA/7SQKP/07t//////////////////9vHl/7eUMf+mfAD/p30A
/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/6yEEf/m2rj//////////////////fz3/+fMa//XqQH/
16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9epAP/WqQH/2rEY/+C9Pf/jxVX/48NQ/9+7N//Z
rxL/1qkA/9eqAP/XqgD/16oA/9apAP/kxVf//v34/+PVrv+pgAf/pnwA/62FEv/q4MP/////////
////////28mY/6d+A/+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnsA/8mwZ//9/Pr/////
////////////796f/9isCf/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/1qkA/9mvFf/oz3P/
9+7O//368//+/fr//v35//z57//168b/58xs/9mvEv/WqQD/16oA/9eqAP/YrQv/8uWy//by6P+1
kSr/pnwA/6mAB//ez6L////////////59+//vJw//6Z7AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+mfAD/r4kb/+3lzv/////////////////58tv/3bcs/9apAP/XqgD/16oA/9eqAP/XqgD/16oA
/9eqAP/WqQD/3rgw//PmuP/+/vz//////////////////////////////////v37//Lksv/dtin/
1qkA/9eqAP/WqAD/48VW//379f/Gq1z/pXsA/6h+BP/byZj////////////m2rf/qoIL/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+mewD/zLNt//7+/f////////////7+/P/oznD/1qkA/9eq
AP/XqgD/16oA/9eqAP/XqgD/16oA/9apAP/fuzj/9+/Q//////////////////r9///m8/3/3+/9
/+Lx/f/y+P7//v/////////168X/3LUm/9epAP/XqQD/2rEa//nx1//Ww4v/pnwA/6d+Av/VwIf/
//////7+/f/KsWn/pnsA/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d8AP+thhP/6+HG////////
//////////Xrxf/asBb/16kA/9eqAP/XqgD/16oA/9eqAP/XqgD/1qkA/924Lf/37s//////////
////////2ez8/4PD9/9PqvT/SKb0/0qn9P9is/X/oNH5/+j0/f//////8eKq/9itDf/XqgD/16oC
//Hgo//j1rL/qH8F/6d9Af/Uv4X///////Xw4v+0kCj/pnwA/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6Z7AP/CpVD//Pv3/////////////v36/+XJYf/WqQD/16oA/9eqAP/XqgD/16oA/9eqAP/X
qQD/2a8S//Lls/////////////7+//+/4Pv/Uqv0/zOc8/80nfP/NZ3z/zWd8/8znPP/NZ3z/2Cy
9f/P6Pz//v33/+XIXf/WqQD/1qgA/+nQdv/o3b7/qoEK/6d+A//ayJX//////+LUrf+ofwb/p30A
/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6h+A//dzZ7/////////////////9uzK/9qwFv/XqQD/
16oA/9eqAP/XqgD/16oA/9eqAP/XqQD/6M9z//79+////////////8Ti+/9IpvT/NJ3z/zae8/82
nvP/Np7z/zae8/82nvP/Np7z/zOc8/9VrfT/2+7///Xouv/YrQ3/1qgA/+TGV//s4sb/rIUQ/6h+
BP/czJ3//////8y0b/+lewD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/7GMIf/y7dz/////
////////////6dB2/9apAP/XqgD/16oA/9eqAP/XqgD/16oA/9apAP/dtyn/+fPc////////////
3e79/1at9f8znfP/Np7z/zae8/82nvP/Np7z/zae8/82nvP/Np7z/zae8/8znPP/g8P4//j37v/f
uzj/1qcA/+PET//s4sT/rYYR/6qCDP/l2LX/+fbt/7qZOv+mewD/p30A/6d9AP+nfQD/p30A/6d9
AP+nfQD/pnsA/8KmUv/9/Pn////////////79uX/3bct/9epAP/XqgD/16oA/9eqAP/XqgD/16oA
/9epAP/r1of////////////5/P7/f8H3/zOc8/82nvP/Np7z/zae8/82nvP/NZ3z/zWd8/85n/P/
NZ3z/zSd8/81nfP/Saf0/9zt/P/oymL/1qcA/+PDTf/o3Ln/qoIK/6+KG//v59L/7eTL/6+IGP+m
fAD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/9bCif/////////////////y46//16sH/9eq
AP/XqgD/16oA/9eqAP/XqgD/1qkA/9uzH//48dj////////////D4vv/PqLz/zWd8/82nvP/Np7z
/zae8/80nfP/S6j0/5nO+P/B4fv/odH5/1Os9P81nfP/N57z/7Xc/f/t1YH/1qcA/+TGVf/j1q//
p34D/7mYN//49ez/38+i/6mAB/+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/qYEJ/+bauf//
///////////////ozm//1qgA/9eqAP/XqgD/16oA/9eqAP/XqgD/1qgA/+XHXP/+/vv///////n8
/v93vff/M5zz/zae8/82nvP/Np7z/zSd8/9OqfT/yeX7/////////////////9Lp/P9QqvT/MZzy
/5jO/P/u2Iv/1qcA/+fLZ//YxpH/pXoA/8mvY//+/v3/0bt9/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6d9AP+mfAD/r4ob//Hq1/////////////368v/gvT3/1qkA/9eqAP/XqgD/16oA/9eqAP/X
qgD/16oB/+7cm////////////9ns/P9HpvT/NZ3z/zae8/82nvP/Np7z/zif8/+p1fr/////////
//////////////////+VzPj/MJvy/5XM+v/r0nj/1qgA/+zXjP/KsGn/pnsA/93Nn///////xKhV
/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+mfAD/tZIs//f06v////////////nz3P/bsx3/
16kA/9eqAP/XqgD/16oA/9eqAP/XqgD/2a4P//Xrxv///////////6zX+v82nvP/Np7z/zae8/82
nvP/NJ3z/1qv9f/r9f7///////////////////////////+63fv/N57z/6TS9v/nx1f/2KwJ/+3d
qf+3lTT/r4kb//Hr2P//////vqBI/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+mewD/vJw+
//v58v////////////Xqw//YrQ3/16oA/9eqAP/XqgD/16oA/9eqAP/XqQD/27Ic//ny2///////
/////4zH+P8znPP/Np7z/zae8/82nvP/M5zz/4HC9//+/v////////////////////////////+s
1/r/P6P1/8je4//ftyj/37o0/+PTpf+pgAn/xapb//38+v//////vZ5D/6Z8AP+nfQD/p30A/6d9
AP+nfQD/p30A/6d9AP+lewD/waRO//38+v////////////PltP/Xqwb/16oA/9eqAP/XqgD/16oA
/9eqAP/XqQD/27Md//nz3f///////v///4PD9/8znPP/Np7z/zae8/82nvP/Mpzz/4rG+P//////
/////////////////////+/3/v9ptvb/aLf5/+bcqf/Yqwf/6dF9/8mwZv+pgAj/5Niz////////
////vZ9D/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+lewD/waRO//38+v////////////Pl
tP/Xqwb/16oA/9eqAP/XqgD/16oA/9eqAP/XqQD/27Ic//nz2////////////4vH+P8ynPP/Np7z
/zae8/82nvP/M53z/2i29v/u9v7////////////4/P7/1ev8/3e99/9EpfX/wNzq/+PAQv/ctSP/
5tak/66IGP+/oUn/+vjy////////////vqBI/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+m
ewD/u5o7//r48f////////////XpwP/YrQz/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/2a4O//Xq
wv///////////7jc+v85n/P/NZ7z/zae8/82nvP/Np7z/zif8/9qt/b/l8z5/4/J+P9vufb/Q6Tz
/0Gk9f+p1Pb/6dJ9/9irBv/p0oD/xqtd/6qCDf/l2bX/////////////////xqtd/6Z8AP+nfQD/
p30A/6d9AP+nfQD/p30A/6d9AP+mfAD/s48l//Xw4/////////////nz3v/btCD/16kA/9eqAP/X
qgD/16oA/9eqAP/XqgD/1qkA/+jQdv///v7///////P5/v9/wff/N57z/zOc8/80nfP/NZ3z/zSd
8/8xm/P/MJvz/zCb8v87oPP/bLn5/8Xh9f/r2I7/2KwL/+PDTf/YxIj/qYAL/8uzbP/9/Pn/////
////////////1sOL/6d+Av+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/q4MN/+newP//////
//////78+P/jxFL/1qgA/9eqAP/XqgD/16oA/9eqAP/XqgD/16kA/9qwFv/y5LH////+///////x
+P7/rtj6/3S79v9ar/X/Saf0/0uo9P9esfX/cbv4/5fO/P/J5fz/7uzX/+nMaP/Yqwn/4b9B/+HP
lv+uiRz/t5U0//Tu3v//////////////////////6N29/6yFEv+mfQD/p30A/6d9AP+nfQD/p30A
/6d9AP+nfQD/pnwA/9C6ef/////////////////x4qz/2KwK/9eqAP/XqgD/16oA/9eqAP/XqgD/
16oA/9apAP/asRr/69aJ//nz3v/+/fv///////v+///u+P//4vH//+Lx/f/v9vn/9vTo//bpvv/r
0XT/3LQi/9epA//kxFP/5NSg/7SRLP+wih3/6N2/////////////////////////////+fbu/7yc
P/+mewD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/7OPJf/x69j////////////9/Pb/5stn
/9epAf/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqQD/16oD/9y1JP/jxFP/6M90/+3Zk//u25f/
7NaG/+jMaP/kxFL/3bgt/9itDP/WqAD/27Id/+rUhP/fzpz/so0l/66IGv/j1rD/////////////
/////////////////////////9nHk/+nfQL/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z8
AP/Jr2T/+/nz////////////+/fq/+bKZP/Yqwj/1qkA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA
/9epAP/WqAD/1qkA/9apAP/WqQD/1qkA/9aoAP/WpwD/1qkC/9y0IP/oznH/7uG1/9G7e/+rgxH/
sYwg/+PWsf////7///////////////////////////////////////fz5/+6mjv/pnsA/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+ofwb/zbVv//j17f////////////379P/w36P/4L5C/9mu
EP/XqQL/1qgA/9aoAP/WqQD/1qgA/9aoAP/WqAD/1qgA/9aoAP/WqQL/2KwJ/9y0Iv/kxFL/7tuV
//Hmw//dzJ3/uZg4/6Z8Av+6mjv/6uHE////////////////////////////////////////////
///////////l2bb/rocW/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30E/7+hSv/o
3b3//Pr2/////////////fry//Xrx//t2pP/6M90/+PDUP/hv0P/4b9D/+HAQ//hwEf/5chd/+rS
ff/u25X/9Oi7//Xt0v/s48f/1sKL/7mYOP+nfQT/q4MP/821cP/18OP/////////////////////
///////////////////////////////////////+/v3/3s+i/66IGP+mewD/p30A/6d9AP+nfQD/
p30A/6d9AP+nfQD/p30A/6Z7AP+shRH/wqVQ/9vKmP/t5Mv/9/Pp//v59P/////////+//79+f/9
/Pb//fv1//r26//38uT/9e/g/+zkzP/g0qv/0Lp7/72eRf+thhX/pXoA/6h/Cf+/oUn/5tq4//38
+f///////////////////////////////////////////////////////////////////////v79
/+XZtf+4ljP/pnwC/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfAD/pnsA/6d9A/+thhP/
tZEr/7ubPf/Gq13/yK1i/8itYv/IrWL/x6xg/76gRv+2lDD/tJAn/6yEEP+nfgX/pHkA/6V6AP+s
hRL/wqVR/+LVrv/6+PH/////////////////////////////////////////////////////////
///////////////////////////////////08OL/076C/7SRKv+ofgX/pXsA/6Z7AP+mfAD/p30A
/6d9AP+nfQD/p30A/6d9AP+mfAD/pnwA/6Z7AP+lewD/pXsA/6V7AP+legD/pXoA/6V6AP+keQD/
pXoA/6d9A/+thxX/vJxA/9O+gv/s48n//Pr2////////////////////////////////////////
/////////////////////////////////////////////////////////////////////v7+//Tw
4v/ez6T/yK1i/7eVM/+viBj/qYEJ/6h/Bf+nfQH/pnwA/6Z8AP+mfAD/pnwA/6Z8AP+mfAD/p34D
/6h/B/+qgQr/r4gY/7SQJ/++oEf/zLRv/93Nn//u5s//+vjy////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////v37//fz6P/t5Mv/4dSs/9vJmP/PuHb/ybBl/8iu
Y//IrWP/yK5j/8mvY//MtG7/1cCF/97Oov/i1K3/7eTL//Tu3//7+fX//v79////////////////
////////////////////////////////////////////////////////////////////////////
////////////////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAKAAA
AEAAAACAAAAAAQAgAAAAAAAAQAAAJRYAACUWAAAAAAAAAAAAAP//////////////////////////
////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////7+fP/9fHj//Tv
4f/z7t7/8+7f//Tv4f/18OL/+fbu//7+/f//////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
///8+/j/8OnV/9/QpP/NtnP/waRP/7WSK/+zjyf/s48m/7OPJv+zjyf/tJAp/72eRP/JsGj/1cGJ
/+bauP/18OL//fz6////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
//////////////////////////////j06//g0aj/xKdX/7CLHv+ofgT/pXsA/6Z7AP+mfAD/pnwA
/6Z8AP+mfAD/pnwA/6Z8AP+mewD/pXoA/6Z8Af+qgQr/tJAq/8esYP/h0qn/9vLm///+/v//////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////+fbu/93Nn/+6mjz/qX8J
/6V7AP+mfAD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6Z8AP+lewD/qH8I/7eVMv/VwYn/8+7e///+/v//////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
///////9/fv/59y8/7+gSP+ofwj/pXsA/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+mewD/pn0D/7WRK//Y
xY//+PTq////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////49ez/0rx+/62GFf+lewD/p30A/6d9AP+nfQD/
p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+mfAD/p34E/72eQ//p3sD//v79////////////////////
////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////w6dX/
waRQ/6d9BP+mfAD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+lewD/roga/9fEjf/7+fP/////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////v/p3sD/t5Ux/6Z7AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z8AP+ofwf/yrBm//fz6P//////////
////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////+/v/k2LT/sYwi/6Z7AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A
/6d9AP+nfQD/p30A/6Z8Av/Dp1T/9O/g////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
///////////////j1bD/sIod/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A
/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnsA/8GkUf/28eT/
////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////k1rD/sIsf/6Z7AP+nfQD/p30A/6d9
AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A
/6d9AP+mfAD/pnwA/6Z8AP+mfAD/pnwA/6Z9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6d9AP+nfQD/p30A/6d9AP+mfAH/xKlX//f06f//////////////////////////////////
////////////////////////////////////////////////////////////////////////////
///p38H/sYwh/6Z7AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A
/6d9AP+nfQD/p30A/6d9AP+nfQD/pnsA/6Z8Af+ofwb/r4ka/7KNI/+yjSP/so0j/7GMIP+rgw3/
p30D/6Z7AP+mewD/p3wA/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9Af/M
tGz//Pv2////////////////////////////////////////////////////////////////////
///////////////////////////////////y69r/uJY2/6Z7AP+nfQD/p30A/6d9AP+nfQD/p30A
/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z8AP+lewD/q4MP/7ubPv/Ru37/
4tWu//Do0//18OL/9fDi//Xw4v/z7dz/6N28/97PpP/NtnH/u5w+/6yFE/+mfAD/pnwA/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+mfAD/qoEK/97On///////////////////////////////
///////////////////////////////////////////////////////////////////59u3/w6ZV
/6Z7AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6Z7AP+shRP/x6xf/+fbuv/59+/////+////////////////////////////////////////
//////7+//r38P/r4cb/0bp7/7WRLP+nfQP/pnwA/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z8
AP+0kSr/8OnV////////////////////////////////////////////////////////////////
///////////////////////9/Pn/z7h4/6d9A/+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/6h/B//Bo0//6N2+//z7+P//////////////////
//////////////////////////////////////////////////////////7+/f/07t//1MCF/7KN
I/+mewD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnsA/8esYP/8+/f/////////////////////
////////////////////////////////////////////////////////////3s+i/6qCDf+mfAD/
p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/6+JG//X
xI//+ffv////////////////////////////////////////////////////////////////////
//////////////////////////////7+/v/u59H/xalZ/6h/CP+mfAD/p30A/6d9AP+nfQD/p30A
/6Z8AP+rgw//49aw////////////////////////////////////////////////////////////
////////////////8erW/7SQKP+mfAD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+n
fQD/p30A/6d9AP+nfQD/pnwA/7eWM//o3b7//v79////////////////////////////////////
/////////v79//78+P/9/Pf//fv0//389v/+/Pj//v37////////////////////////////////
//r48f/Vwon/rIUT/6Z8AP+nfQD/p30A/6d9AP+nfQD/pnsA/7+gSP/69/H/////////////////
////////////////////////////////////////////////+/nz/8arX/+mfAD/p30A/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwB/76fRv/w6dX/////////
//////////////////////////////7+/f/69OH/8eGs/+jPdf/iwUv/4cBI/+C+RP/hwEf/4cBJ
/+XIX//t2pX/9uvH//z68f///////////////////////v38/9/Po/+viBn/pnwA/6d9AP+nfQD/
p30A/6d9AP+pgQr/4tWu////////////////////////////////////////////////////////
/////////93Mnf+ogAj/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+nfQD/pnwB/8CiTP/07+D///////////////////////////////////79//fv0f/o0Hj/3LYq
/9erB//WqQD/1qgA/9aoAP/WqQD/1qgA/9aoAP/WqQD/16kB/9mvE//hwEf/7t2b//v36P//////
/////////////v7/4NGn/6yFEv+mfAD/p30A/6d9AP+nfQD/pnsA/8KlUf/8+vX/////////////
//////////////////////////////////////////Dq1v+0kSv/pnwA/6d9AP+nfQD/p30A/6d9
AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnsA/8CiTf/07+H/////////////////////
/////////////Pjs/+vWiP/btCH/1qkA/9epAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/
16oA/9eqAP/XqgD/1qkA/9erBf/fvDv/8eKr//389/////////////79/P/Ww4n/qYAH/6d9AP+n
fQD/p30A/6d8AP+thhP/6+LF//////////////////////////////////////////////////39
+v/Ls23/pnsA/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnsA
/7iXNf/y69r/////////////////////////////////9+/S/+LCTv/XqgT/1qkA/9eqAP/XqgD/
16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/1qkA/9itDf/n
zW3/+/bm////////////+/r0/8mwZv+mfAD/p30A/6d9AP+nfQD/pnwA/9K9f///////////////
///////////////////////////////////n3Lv/rIUS/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A
/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/7CLH//p38D/////////////////////////////////
9Oi8/924Lf/WqQD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/X
qgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqQD/1qkC/+HBSP/48dj////////////07+D/uJY0/6Z7
AP+nfQD/p30A/6V7AP+8nED/+vjx///////////////////////////////////////6+PL/waNO
/6Z7AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/6qCDf/dzaD/
////////////////////////////////8uW0/9u0JP/WqQD/16oA/9eqAP/XqgD/16oA/9eqAP/X
qgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eq
AP/WqQD/37w7//jw1P///////////97Oov+pgQn/p30A/6d9AP+mfAD/rYYV/+3lzf//////////
////////////////////////////4NKo/6mBCv+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6d9AP+nfQD/p30A/6d9Av/Ot3b//fz5////////////////////////////9OnB/9uzIf/W
qQD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eq
AP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9aoAP/hwEn/+/bn///////6+PH/v6FJ
/6V7AP+nfQD/p30A/6d9Av/czJ3/////////////////////////////////+fbu/72dQv+mewD/
p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z7AP+5mDf/9fDj////////
////////////////////+PHY/966NP/WqQD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eq
AP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA
/9eqAP/XqgD/1qkB/+fMbP/9/Pb//////+DRp/+pgAf/p30A/6d9AP+lewD/zLRw////////////
/////////////////////9/Qpf+pgAj/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+n
fQD/p30A/6d8AP+rgw//49ax/////////////////////////////Pjs/+PDUf/WqQD/16oA/9eq
AP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/1qkA/9apAP/XqgP/2KwL
/9isCf/WqQH/1qkA/9apAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/YrAr/8N+k///////38+j/
uJYz/6Z7AP+nfQD/pnsA/76fRv/7+fT///////////////////////r38P++n0b/pnsA/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+mewD/yK5j//z79///////////////
/////////v36/+nRev/XqgP/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA
/9eqAP/WqQD/2KsI/9+8Ov/q0n3/792d//Lks//x4q3/7tuW/+fNbv/duDH/16sG/9epAP/XqgD/
16oA/9eqAP/XqgD/1qkA/966Nf/69eP//////9C6ef+mewD/p30A/6Z8AP+2lC//9fHj////////
///////////////j1rD/qoEL/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+mfAD/sIoe/+7lzv////////////////////////////Lks//YrhD/16kA/9eqAP/XqgD/16oA
/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/WqQL/3ro2/+/fo//8+Ov////+////////////
///////////+/v3/+vXl/+7cmv/duDD/1qkB/9eqAP/XqgD/16oA/9eqAP/XqgL/7NiP///////n
3L3/qoIN/6Z9AP+mfAD/rogY/+3lzv/////////////////8+/j/xKhY/6V7AP+nfQD/p30A/6d9
AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/9C5ev/+/v7/////////////////////
//v25v/gvT7/1qkA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9epAP/Yqwj/
5stp//n04P//////////////////////////////////////////////////////+fLc/+XIX//X
qgX/16oA/9eqAP/XqgD/1qkA/967OP/8+Oz/9vLn/7WSLP+mfAD/pnwA/66HFv/s5Mv/////////
////////7eTM/66IF/+mfAD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA
/7KNIv/w6tb//////////////////////////v/r1YT/16oC/9eqAP/XqgD/16oA/9eqAP/XqgD/
16oA/9eqAP/XqgD/16oA/9apAP/YrAz/69WG//379P//////////////////////////////////
///////////////////////////////8+vD/6M90/9eqBv/XqgD/16oA/9eqAP/YrAn/8uSy//79
/f/Ep1b/pXsA/6Z9AP+shBH/59u7/////////////////9K9gP+mfAD/p30A/6d9AP+nfQD/p30A
/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z7AP/Ot3X///7+///////////////////////379H/
27Mf/9epAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9epAP/YrAz/69aI//79+P//
////////////////////+/3//9ns/P+x2fr/qNX6/6vW+v+02vr/2+39//j8/v////////////36
8v/lyWP/16kA/9eqAP/XqgD/1qkA/+fNbf//////0Ll5/6Z7AP+nfQD/q4IN/+PVr///////////
//j06/+5lzb/pnsA/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z8AP+uhxb/
7OPK///////////////////////+/fv/58xq/9apAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/X
qgD/16oA/9eqAP/XqgT/6dF7//78+P//////////////////////4vH9/4nG+P9Jp/T/Np7z/zSd
8/80nfP/N57z/0mn9P95vvf/yOT7//v9////////+vTh/966Nf/WqQD/16oA/9apAP/fuzj//fvy
/97Oo/+nfQL/p30A/6uDDv/k1rL////////////m2rj/qoIM/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6d9AP+nfQD/p30A/6d9AP+lewD/w6dV//z79///////////////////////9uzI/9qwGP/X
qQD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/WqQD/48RT//z57v//////////////
////////zOb8/12w9f80nfL/NZ3z/zae8/82nvP/Np7z/zae8/81nfP/M5zy/0Ok8/+Yzfj/8/n+
///////w4KT/2KwJ/9eqAP/XqQD/2rIc//nz2//i1K7/qH4E/6Z8AP+thhP/6t/C////////////
zbZy/6Z7AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/qH8G/9/Rpf//
/////////////////////v78/+fMa//WqQD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eq
AP/XqQD/27Mg//bty///////////////////////x+T7/06p9P8znfP/Np7z/zae8/82nvP/Np7z
/zae8/82nvP/Np7z/zae8/81nfP/N5/z/4nG9//1+v///fnu/+C+QP/WqQD/16oA/9esCP/057r/
6N2//6qCC/+mfAD/rocX/+3kzP//////+PXs/7iXNv+mewD/p30A/6d9AP+nfQD/p30A/6d9AP+n
fQD/p30A/6d9AP+nfQD/pnwA/7SRKf/18OH///////////////////////jw1P/bsx7/16kA/9eq
AP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oD/+zXjP//////////////////////2u38
/1at9P8znPL/Np7z/zae8/82nvP/Np7z/zae8/82nvP/Np7z/zae8/82nvP/Np7z/zWd8/84n/P/
q9b5///////t2ZL/16oC/9eqAP/XqgX/8+Sx/+vjx/+shQ//pnwA/6+IGv/u5tD//////+rgxf+s
hBD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z7AP/Jr2X//v79////
///////////////////r1Yf/16kA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/1qkA
/9+8Of/79+f/////////////////7/f+/2659v8znPP/Np7z/zae8/82nvP/Np7z/zae8/82nvP/
Np7z/zae8/82nvP/Np7z/zae8/82nvP/NJ3z/1mv9f/o9P//+O/Q/9mwF//XqQD/16oD//HhqP/r
4sX/rIQO/6V7AP+3lTL/9vLn///////YxpH/pnwA/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+nfQD/p30A/6d9AP+ofgT/38+j///////////////////////8+O3/37s6/9apAP/XqgD/16oA
/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9erBf/u3Jv//////////////////////6HR+f82nvP/
Np7z/zae8/82nvP/Np7z/zae8/82nvP/Np7z/zWe8/8znPP/Mpzz/zOd8/82nvP/Np7z/zae8/83
nvP/sNn7//767v/eujb/1qkA/9eqAv/w4KT/5tq6/6qBCf+lewD/vp9H//v69f/+/fz/xqte/6V7
AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+mfAD/r4ka//Dp1f//////////
////////////9Oe7/9itDf/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9apAP/euTL/
+/bm/////////////////9rt/f9NqfT/NJ3z/zae8/82nvP/Np7z/zae8/82nvP/Np7z/zSd8/9A
ovP/aLb2/3m+9/9gsvX/O6Dz/zSd8/82nvP/M5zz/3u/9//7+/j/48NQ/9apAP/XqgT/8uSv/+HT
rf+nfgP/pXsA/8y0cP//////9/Pn/7iWMv+mewD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A
/6d9AP+nfQD/pXsA/7ubPf/6+PH//////////////////////+nRev/WqQD/16oA/9eqAP/XqgD/
16oA/9eqAP/XqgD/16oA/9eqAP/WqQD/6tJ9//////////////////3+//+OyPj/NJ3z/zae8/82
nvP/Np7z/zae8/82nvP/Np7z/zSd8/9br/X/weH7//X6/v/9/v//7/f+/7DY+v9NqfT/NJ3z/zSd
8/9br/X/7fb+/+fLaP/WqAD/16sF//PltP/ayZn/pnwB/6d9Af/by5r//////+3lzP+viRr/pnwA
/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6V7AP/KsWv///7+////////////
//////368f/gvUD/1qkA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/2a4Q//XqxP//
///////////////h8P3/T6r0/zSd8/82nvP/Np7z/zae8/82nvP/Np7z/zSd8/9Zr/X/2ez8////
////////////////////////ut37/z+i8/80nfP/Sqf0/+Lx/v/ozWr/1qgA/9muEv/268f/zLNv
/6V6AP+shRL/7OLI///////i1K7/qYEK/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6d9AP+mfAD/1sOM///////////////////////48NX/2rEa/9epAP/XqgD/16oA/9eqAP/X
qgD/16oA/9eqAP/XqgD/1qkA/966Nf/8+Oz/////////////////qtb6/zae8/82nvP/Np7z/zae
8/82nvP/Np7z/zWd8/89ofP/ud37//////////////////////////////////f7/v9yu/b/Mpzy
/0qo9P/i7/j/5cdY/9aoAP/ctij/9u/Z/76fR/+keQD/uZg3//n27f//////1sOK/6h+BP+nfQD/
p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/qH8H/+XYtf//////////////////
////8eKs/9erB//XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9aoAP/lyGD///79////
////////+vz+/3S89v8znPP/Np7z/zae8/82nvP/Np7z/zae8/8znPP/cLr2//b6/v//////////
////////////////////////////ntD5/zOc8v9OqfX/4+7w/+G9PP/WpwD/48NP/+/n0P+wix7/
pXoA/863dP///////////8qwaP+mfAD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+n
fQD/p30A/6qBC//o3b7//////////////////////+zYkP/WqQD/16oA/9eqAP/XqgD/16oA/9eq
AP/XqgD/16oA/9eqAP/WqQD/7NeO/////////////////+Xy/f9Rq/T/NJ3z/zae8/82nvP/Np7z
/zae8/82nvP/N57z/67Y+v///////////////////////////////////////////6zW+v8znPP/
aLb4/+/t2v/csyD/1qkA/+3YjP/ez6T/p30D/6qCDP/m27r////////////IrmT/pnwA/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z8AP+vihv/8OnV////////////////////
///my2r/1qgA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/1qkB/+7dnP//////////
///////Y7Pz/QqTz/zWd8/82nvP/Np7z/zae8/82nvP/NZ7z/0Cj8//T6fz/////////////////
//////////////////////////+Ryvj/MZvy/5PL/P/y4qz/16sF/9mvFP/06cL/xapd/6R5AP+7
mz7/+fbu////////////x6xe/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+mfAD/so4k//Xw4//////////////////+/vz/5MZZ/9aoAP/XqgD/16oA/9eqAP/XqgD/16oA
/9eqAP/XqgD/16oA/9eqAf/v3p7/////////////////zuf8/0Ci8/81nvP/Np7z/zae8/82nvP/
Np7z/zWd8/9DpPP/2Oz8///////////////////////////////////////l8v3/WK71/0Kj9P/P
5vj/58lh/9WnAP/jw1H/7OLE/6+JGv+mfAH/2ceU/////////////////8asXP+mfAD/p30A/6d9
AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/7OPJf/18eT//////////////////v78
/+TGWf/WqAD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/WqQH/792d////////////
/////9Lp/P9Bo/P/NZ7z/zae8/82nvP/Np7z/zae8/81nvP/PqLz/8rl+///////////////////
///////////////l8v3/er/3/zOc8/+ExPr/8enG/9qwF//YrAj/8OGr/8+5ef+legD/tpMu//Xw
4v/////////////////HrWH/pnwA/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A
/6Z8AP+yjSH/9O7f//////////////////7+/f/kxln/1qgA/9eqAP/XqgD/16oA/9eqAP/XqgD/
16oA/9eqAP/XqgD/1qkA/+7bmP/////////////////g8P3/Sqf0/zWd8/82nvP/Np7z/zae8/82
nvP/Np7z/zWd8/93vff/5fL9//v9///7/f//9fr+/97v/f+r1vr/XbD1/zKc8v9fsvb/4e3w/+XG
V//WpwD/48NO/+vgwP+wix//p30B/9fEjf//////////////////////ya9m/6Z8AP+nfQD/p30A
/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfAD/rIUR/+zix///////////////////////
6M5y/9apAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9aoAP/my2j//v7+////////
////+fz+/3q+9/8ynPP/Np7z/zae8/82nvP/Np7z/zae8/82nvP/Np7z/1Wt9P94vff/fL/3/2W0
9f9MqPT/NZ3z/zGc8/9fsvb/0+n5/+3Wg//XqgT/2a8T//Hktf/IrmT/pHkA/7qZOf/38+f/////
/////////////////9C5d/+nfQH/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6l/B//l2Lb//////////////////////+7cmv/XqQH/16oA/9eqAP/XqgD/16oA/9eqAP/X
qgD/16oA/9eqAP/WqQD/3LYp//nz3v/////////////////R6Pz/UKr0/zKc8/81nfP/Np7z/zae
8/82nvP/Np7z/zae8/80nfP/M5zz/zKc8/8xm/L/Mpzy/0al9P+Lx/n/4/D5/+/cl//YrQ7/16oD
/+rTf//cy5n/qYEK/6uEEP/j1rD////////////////////////////f0ab/qYAI/6d9AP+nfQD/
p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+mfAD/1sKK///////////////////////2
7Mn/2a8U/9epAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAf/p0Hf//v36////
/////////////8/o/P9vufb/QaPz/zWd8/8znPL/Mpzz/zKc8/8znPL/NJ3y/zae8/9DpPT/XLD1
/5DK+f/T6v//+Pbq/+vTff/YrQ//1qkB/+bJYP/m2bL/sIsg/6V7AP/NtXD//fz6////////////
////////////////7eTL/6+JGf+mfAD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+n
fQD/pXsA/8KkUv/8+/f//////////////////fvz/+HASP/WqAD/16oA/9eqAP/XqgD/16oA/9eq
AP/XqgD/16oA/9eqAP/XqgD/2K0N/+zYjf/9+/T/////////////////9Pr+/83m/P+t1/r/jMf4
/3S89v9yu/b/fsD3/6HR+f+y2vv/0en+/+73///8+fD/9OSv/+C+Qv/XqgT/1qkD/+bKY//s4cD/
t5U1/6R6AP+7m0D/9fDj//////////////////////////////////n27f+8nD7/pXsA/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z8AP+uiBj/7eXM////////////////////
///x4an/2KwL/9epAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9apAP/YrAn/5MZa
//Tovv/8+vH////+//////////////////7////8/v//+/7///3+/////vv///rv//nuzP/u2ZH/
4b9D/9isDP/WqAD/2K0O/+rRev/t4sL/vJ1C/6V6AP+1kSr/7eTL////////////////////////
////////////////////0r2B/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+nfQD/pnwA/821cP/+/fz//////////////////fz1/+bKZP/WqQH/16oA/9eqAP/XqgD/16oA
/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9apAP/ZrhH/4L5B/+jOcf/s14z/8eOy//TowP/06L//
8eKw/+zYkP/p0Xr/5clj/967OP/asBf/16kC/9aoAP/WqQH/3rgw//DhqP/o3Lv/uJY2/6V6AP+z
jyf/6N6+/////////////////////////////////////////////////+zky/+uhxf/pnwA/6d9
AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6Z8AP+uhxb/6N2+////////////////
///////69eT/48RS/9apAf/XqQD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/
16oA/9apAP/WqAD/16kB/9esCf/YrAv/2KwL/9erCP/XqgL/1qgA/9aoAP/WqQD/1qgA/9apAv/b
syH/6tJ8//bu0//bypn/sIsf/6V6AP+zjyj/59u7////////////////////////////////////
///////////////////9/Pn/yK5k/6Z7AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A
/6d9AP+nfQD/pnwA/7qZOf/w6dT///////////////////////r25v/nzW//2a4R/9aoAP/XqQD/
16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/XqgD/16oA/9eqAP/X
qgD/16kA/9apAP/WqAD/2KwI/965Mv/r1IP/9+/T/+zjyv/Fql3/qYAJ/6V6AP+5lzX/6+HG////
/////////////////////////////////////////////////////////////+7mz/+xjCH/pnwA
/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+mfAD/upk5/+zjyf//////
/////////////////vz4//Pnuf/kx1v/2rId/9eqBP/WqAD/1qgA/9apAP/WqQD/16kA/9epAP/W
qQD/1qkA/9apAP/WqQD/1qgA/9aoAP/WqQD/16oD/9mwFv/eujX/581t//Plsf/69eT/7+fS/8+5
ef+wih3/pXoA/6d+Bv/EqFj/8uvZ////////////////////////////////////////////////
////////////////////////////2ceT/6mACP+mfAD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/
p30A/6d9AP+nfQD/p30A/6Z8AP+yjST/2siW//n27f///////////////////////vz4//fw1P/v
3qL/5stq/+PEU//eujX/27Ie/9qyGv/ashr/2rEa/9qxG//bsh3/3bgt/+LCT//kxVf/6dJ8//Dg
pv/378///Pjr//j17P/n27z/yrFp/7CLHv+mewH/pXoA/7CKHf/Ww43/+ffv////////////////
//////////////////////////////////////////////////////////////////v69f/PuHX/
qH8H/6Z8AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnwA/6h/B/+8
nUH/28ub//Pt3P/8+/j//////////////////////////v/+/fv/+/fp//nz2//58tn/+fLZ//ny
2f/689v/+vTe//z36P/+/fr//v79//r48v/z7uD/5Ni2/8+4eP+5mTr/qoIN/6V7AP+legD/qoEM
/8OnVf/r4sj//v79////////////////////////////////////////////////////////////
////////////////////////////////+/nz/9G8fv+qgg3/pnsA/6d9AP+nfQD/p30A/6d9AP+n
fQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pnsA/6d+Bf+yjSL/xKhY/9TAhv/l2bf/6d/C//Ps
2//59/D/+vjx//r48v/6+PP/+vjz//r48//28eb/7OTL/+jewf/m2rn/1sKJ/8y0cf+9nkP/so0i
/6mACP+mewH/pXoA/6V6AP+qgQv/v6BH/+LUrP/7+fP/////////////////////////////////
///////////////////////////////////////////////////////////////////////////9
+/j/3s6e/7SQKf+mewH/pnwA/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9
AP+nfQD/pnwA/6V7AP+mfAH/qYAJ/6qCDf+yjiT/uJc3/7mYOP+5mDj/uZg4/7mXOP+5lzj/tZEr
/62GE/+pgQv/qYAJ/6Z8Af+lewD/pnsA/6Z7AP+lewD/pnwB/66HF//Dp1b/4tWv//r37///////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////v/x6tj/zbZy/7CKHf+mfAL/pnsA/6Z8
AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+mfQD/pnwA
/6Z7AP+mewD/pnsA/6Z7AP+mewD/pnsA/6Z8AP+mfAD/p30A/6Z8AP+mfAD/pXsA/6Z9Av+thRP/
vJw//9S/hf/s5Mr//Pr2////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
//////////////79+//v59L/07+E/7qaPf+shRP/pnwC/6V7AP+lewD/pnwA/6Z8AP+nfAD/p30A
/6d9AP+nfQD/p30A/6d9AP+nfQD/p30A/6d9AP+nfQD/pn0A/6Z8AP+mfAD/pnwA/6V7AP+lewD/
pnwB/6d9A/+shRP/tJEr/8WpWv/YxZD/6+LI//n37/////7/////////////////////////////
////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////59u7/6uHG
/9rIl//HrWL/vp9E/7KNI/+viR3/rIUS/6mACP+nfgL/p30C/6d9Av+nfQL/p30C/6d9Av+nfQL/
qH8H/6uDDv+uiBn/sIof/7OOJf++n0P/xKlZ/9C5eP/fz6X/6+HG//bx5v/9/Pr/////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////v79//r38P/y7Nv/7+jT/+batv/cy5v/
18SM/9XCiv/VwYr/1cGK/9XBiv/Wwor/18SL/9vKmf/i1Kv/7OPJ//Hq2P/z7dz/+vfv//79/P//
/v7/////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
//////8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAA==')
	#endregion
	$InPlaceUpgradeReadyTool.Margin = '5, 5, 5, 5'
	$InPlaceUpgradeReadyTool.Name = 'InPlaceUpgradeReadyTool'
	$InPlaceUpgradeReadyTool.ShowIcon = $False
	$InPlaceUpgradeReadyTool.ShowInTaskbar = $False
	$InPlaceUpgradeReadyTool.SizeGripStyle = 'Hide'
	$InPlaceUpgradeReadyTool.StartPosition = 'CenterScreen'
	$InPlaceUpgradeReadyTool.TopMost = $True
	$InPlaceUpgradeReadyTool.add_Load($InPlaceUpgradeReadyTool_Load)
	#
	# buttonMinimize
	#
	$buttonMinimize.BackColor = 'Transparent'
	$buttonMinimize.FlatAppearance.BorderColor = '24, 68, 137'
	$buttonMinimize.FlatStyle = 'Flat'
	$buttonMinimize.Font = 'Microsoft Sans Serif, 10pt, style=Bold'
	$buttonMinimize.ForeColor = 'Black'
	$buttonMinimize.Location = '320, 349'
	$buttonMinimize.Name = 'buttonMinimize'
	$buttonMinimize.Size = '85, 37'
	$buttonMinimize.TabIndex = 10
	$buttonMinimize.Text = 'Minimize'
	$buttonMinimize.UseCompatibleTextRendering = $True
	$buttonMinimize.UseVisualStyleBackColor = $False
	$buttonMinimize.add_Click($buttonMinimize_Click)
	#
	# labelDriverMessage
	#
	$labelDriverMessage.BackColor = 'Transparent'
	$labelDriverMessage.Font = 'Microsoft Sans Serif, 9.75pt'
	$labelDriverMessage.ForeColor = 'Blue'
	$labelDriverMessage.Location = '10, 256'
	$labelDriverMessage.Name = 'labelDriverMessage'
	$labelDriverMessage.Size = '490, 30'
	$labelDriverMessage.TabIndex = 9
	$labelDriverMessage.Text = 'DriverMessage'
	$labelDriverMessage.TextAlign = 'MiddleCenter'
	$labelDriverMessage.UseCompatibleTextRendering = $True
	#
	# labelPowerConnected
	#
	$labelPowerConnected.AutoSize = $True
	$labelPowerConnected.BackColor = 'Transparent'
	$labelPowerConnected.Font = 'Microsoft Sans Serif, 12pt'
	$labelPowerConnected.ForeColor = '0, 192, 0'
	$labelPowerConnected.Location = '141, 322'
	$labelPowerConnected.Name = 'labelPowerConnected'
	$labelPowerConnected.Size = '133, 24'
	$labelPowerConnected.TabIndex = 8
	$labelPowerConnected.Text = 'Power connected'
	$labelPowerConnected.UseCompatibleTextRendering = $True
	#
	# picturebox1
	#
	#region Binary Data
	$picturebox1.Image = [System.Convert]::FromBase64String('
/9j/4AAQSkZJRgABAQEAYABgAAD/4QFERXhpZgAATU0AKgAAAAgACwEaAAUAAAABAAAAkgEbAAUA
AAABAAAAmgEoAAMAAAABAAIAAAExAAIAAAARAAAAogEyAAIAAAAUAAAAtAMBAAUAAAABAAAAyAMC
AAIAAAAMAAAA0FEQAAEAAAABAQAAAFERAAQAAAABAAAOxFESAAQAAAABAAAOxIdpAAQAAAABAAAA
3AAAAAAAAABgAAAAAQAAAGAAAAABcGFpbnQubmV0IDQuMC4xNgAAMjAxMzowNDoyNiAxNTo0ODow
OQAAAYagAACxjklDQyBQcm9maWxlAAAEkAMAAgAAABQAAAESkAQAAgAAABQAAAEmkpEAAgAAAAMw
MAAAkpIAAgAAAAMwMAAAAAAAADIwMTI6MDc6MTEgMTY6MjE6NDQAMjAxMjowNzoxMSAxNjoyMTo0
NAAAAP/iDFhJQ0NfUFJPRklMRQABAQAADEhMaW5vAhAAAG1udHJSR0IgWFlaIAfOAAIACQAGADEA
AGFjc3BNU0ZUAAAAAElFQyBzUkdCAAAAAAAAAAAAAAABAAD21gABAAAAANMtSFAgIAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEWNwcnQAAAFQAAAAM2Rlc2MA
AAGEAAAAbHd0cHQAAAHwAAAAFGJrcHQAAAIEAAAAFHJYWVoAAAIYAAAAFGdYWVoAAAIsAAAAFGJY
WVoAAAJAAAAAFGRtbmQAAAJUAAAAcGRtZGQAAALEAAAAiHZ1ZWQAAANMAAAAhnZpZXcAAAPUAAAA
JGx1bWkAAAP4AAAAFG1lYXMAAAQMAAAAJHRlY2gAAAQwAAAADHJUUkMAAAQ8AAAIDGdUUkMAAAQ8
AAAIDGJUUkMAAAQ8AAAIDHRleHQAAAAAQ29weXJpZ2h0IChjKSAxOTk4IEhld2xldHQtUGFja2Fy
ZCBDb21wYW55AABkZXNjAAAAAAAAABJzUkdCIElFQzYxOTY2LTIuMQAAAAAAAAAAAAAAEnNSR0Ig
SUVDNjE5NjYtMi4xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAABYWVogAAAAAAAA81EAAQAAAAEWzFhZWiAAAAAAAAAAAAAAAAAAAAAAWFlaIAAAAAAAAG+i
AAA49QAAA5BYWVogAAAAAAAAYpkAALeFAAAY2lhZWiAAAAAAAAAkoAAAD4QAALbPZGVzYwAAAAAA
AAAWSUVDIGh0dHA6Ly93d3cuaWVjLmNoAAAAAAAAAAAAAAAWSUVDIGh0dHA6Ly93d3cuaWVjLmNo
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGRlc2MAAAAAAAAA
LklFQyA2MTk2Ni0yLjEgRGVmYXVsdCBSR0IgY29sb3VyIHNwYWNlIC0gc1JHQgAAAAAAAAAAAAAA
LklFQyA2MTk2Ni0yLjEgRGVmYXVsdCBSR0IgY29sb3VyIHNwYWNlIC0gc1JHQgAAAAAAAAAAAAAA
AAAAAAAAAAAAAABkZXNjAAAAAAAAACxSZWZlcmVuY2UgVmlld2luZyBDb25kaXRpb24gaW4gSUVD
NjE5NjYtMi4xAAAAAAAAAAAAAAAsUmVmZXJlbmNlIFZpZXdpbmcgQ29uZGl0aW9uIGluIElFQzYx
OTY2LTIuMQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAdmlldwAAAAAAE6T+ABRfLgAQzxQAA+3M
AAQTCwADXJ4AAAABWFlaIAAAAAAATAlWAFAAAABXH+dtZWFzAAAAAAAAAAEAAAAAAAAAAAAAAAAA
AAAAAAACjwAAAAJzaWcgAAAAAENSVCBjdXJ2AAAAAAAABAAAAAAFAAoADwAUABkAHgAjACgALQAy
ADcAOwBAAEUASgBPAFQAWQBeAGMAaABtAHIAdwB8AIEAhgCLAJAAlQCaAJ8ApACpAK4AsgC3ALwA
wQDGAMsA0ADVANsA4ADlAOsA8AD2APsBAQEHAQ0BEwEZAR8BJQErATIBOAE+AUUBTAFSAVkBYAFn
AW4BdQF8AYMBiwGSAZoBoQGpAbEBuQHBAckB0QHZAeEB6QHyAfoCAwIMAhQCHQImAi8COAJBAksC
VAJdAmcCcQJ6AoQCjgKYAqICrAK2AsECywLVAuAC6wL1AwADCwMWAyEDLQM4A0MDTwNaA2YDcgN+
A4oDlgOiA64DugPHA9MD4APsA/kEBgQTBCAELQQ7BEgEVQRjBHEEfgSMBJoEqAS2BMQE0wThBPAE
/gUNBRwFKwU6BUkFWAVnBXcFhgWWBaYFtQXFBdUF5QX2BgYGFgYnBjcGSAZZBmoGewaMBp0GrwbA
BtEG4wb1BwcHGQcrBz0HTwdhB3QHhgeZB6wHvwfSB+UH+AgLCB8IMghGCFoIbgiCCJYIqgi+CNII
5wj7CRAJJQk6CU8JZAl5CY8JpAm6Cc8J5Qn7ChEKJwo9ClQKagqBCpgKrgrFCtwK8wsLCyILOQtR
C2kLgAuYC7ALyAvhC/kMEgwqDEMMXAx1DI4MpwzADNkM8w0NDSYNQA1aDXQNjg2pDcMN3g34DhMO
Lg5JDmQOfw6bDrYO0g7uDwkPJQ9BD14Peg+WD7MPzw/sEAkQJhBDEGEQfhCbELkQ1xD1ERMRMRFP
EW0RjBGqEckR6BIHEiYSRRJkEoQSoxLDEuMTAxMjE0MTYxODE6QTxRPlFAYUJxRJFGoUixStFM4U
8BUSFTQVVhV4FZsVvRXgFgMWJhZJFmwWjxayFtYW+hcdF0EXZReJF64X0hf3GBsYQBhlGIoYrxjV
GPoZIBlFGWsZkRm3Gd0aBBoqGlEadxqeGsUa7BsUGzsbYxuKG7Ib2hwCHCocUhx7HKMczBz1HR4d
Rx1wHZkdwx3sHhYeQB5qHpQevh7pHxMfPh9pH5Qfvx/qIBUgQSBsIJggxCDwIRwhSCF1IaEhziH7
IiciVSKCIq8i3SMKIzgjZiOUI8Ij8CQfJE0kfCSrJNolCSU4JWgllyXHJfcmJyZXJocmtyboJxgn
SSd6J6sn3CgNKD8ocSiiKNQpBik4KWspnSnQKgIqNSpoKpsqzysCKzYraSudK9EsBSw5LG4soizX
LQwtQS12Last4S4WLkwugi63Lu4vJC9aL5Evxy/+MDUwbDCkMNsxEjFKMYIxujHyMioyYzKbMtQz
DTNGM38zuDPxNCs0ZTSeNNg1EzVNNYc1wjX9Njc2cjauNuk3JDdgN5w31zgUOFA4jDjIOQU5Qjl/
Obw5+To2OnQ6sjrvOy07azuqO+g8JzxlPKQ84z0iPWE9oT3gPiA+YD6gPuA/IT9hP6I/4kAjQGRA
pkDnQSlBakGsQe5CMEJyQrVC90M6Q31DwEQDREdEikTORRJFVUWaRd5GIkZnRqtG8Ec1R3tHwEgF
SEtIkUjXSR1JY0mpSfBKN0p9SsRLDEtTS5pL4kwqTHJMuk0CTUpNk03cTiVObk63TwBPSU+TT91Q
J1BxULtRBlFQUZtR5lIxUnxSx1MTU19TqlP2VEJUj1TbVShVdVXCVg9WXFapVvdXRFeSV+BYL1h9
WMtZGllpWbhaB1pWWqZa9VtFW5Vb5Vw1XIZc1l0nXXhdyV4aXmxevV8PX2Ffs2AFYFdgqmD8YU9h
omH1YklinGLwY0Njl2PrZEBklGTpZT1lkmXnZj1mkmboZz1nk2fpaD9olmjsaUNpmmnxakhqn2r3
a09rp2v/bFdsr20IbWBtuW4SbmtuxG8eb3hv0XArcIZw4HE6cZVx8HJLcqZzAXNdc7h0FHRwdMx1
KHWFdeF2Pnabdvh3VnezeBF4bnjMeSp5iXnnekZ6pXsEe2N7wnwhfIF84X1BfaF+AX5ifsJ/I3+E
f+WAR4CogQqBa4HNgjCCkoL0g1eDuoQdhICE44VHhauGDoZyhteHO4efiASIaYjOiTOJmYn+imSK
yoswi5aL/IxjjMqNMY2Yjf+OZo7OjzaPnpAGkG6Q1pE/kaiSEZJ6kuOTTZO2lCCUipT0lV+VyZY0
lp+XCpd1l+CYTJi4mSSZkJn8mmia1ZtCm6+cHJyJnPedZJ3SnkCerp8dn4uf+qBpoNihR6G2oiai
lqMGo3aj5qRWpMelOKWpphqmi6b9p26n4KhSqMSpN6mpqhyqj6sCq3Wr6axcrNCtRK24ri2uoa8W
r4uwALB1sOqxYLHWskuywrM4s660JbSctRO1irYBtnm28Ldot+C4WbjRuUq5wro7urW7LrunvCG8
m70VvY++Cr6Evv+/er/1wHDA7MFnwePCX8Lbw1jD1MRRxM7FS8XIxkbGw8dBx7/IPci8yTrJuco4
yrfLNsu2zDXMtc01zbXONs62zzfPuNA50LrRPNG+0j/SwdNE08bUSdTL1U7V0dZV1tjXXNfg2GTY
6Nls2fHadtr724DcBdyK3RDdlt4c3qLfKd+v4DbgveFE4cziU+Lb42Pj6+Rz5PzlhOYN5pbnH+ep
6DLovOlG6dDqW+rl63Dr++yG7RHtnO4o7rTvQO/M8Fjw5fFy8f/yjPMZ86f0NPTC9VD13vZt9vv3
ivgZ+Kj5OPnH+lf65/t3/Af8mP0p/br+S/7c/23////bAEMAAQEBAQEBAQEBAQEBAQEBAQEBAQEB
AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAf/bAEMBAQEBAQEBAQEB
AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAf/A
ABEIADwAPAMBIgACEQEDEQH/xAAfAAABBQEBAQEBAQAAAAAAAAAAAQIDBAUGBwgJCgv/xAC1EAAC
AQMDAgQDBQUEBAAAAX0BAgMABBEFEiExQQYTUWEHInEUMoGRoQgjQrHBFVLR8CQzYnKCCQoWFxgZ
GiUmJygpKjQ1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoOEhYaHiImKkpOU
lZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4eLj5OXm5+jp6vHy8/T1
9vf4+fr/xAAfAQADAQEBAQEBAQEBAAAAAAAAAQIDBAUGBwgJCgv/xAC1EQACAQIEBAMEBwUEBAAB
AncAAQIDEQQFITEGEkFRB2FxEyIygQgUQpGhscEJIzNS8BVictEKFiQ04SXxFxgZGiYnKCkqNTY3
ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqCg4SFhoeIiYqSk5SVlpeYmZqio6Sl
pqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2dri4+Tl5ufo6ery8/T19vf4+fr/2gAMAwEA
AhEDEQA/AP79s4A6E4GMd/8AOf8AOePlz9qP9sT9nr9jnwQfHHx9+JGi+Dbe6g1GXw14bMy33jfx
xcaZNpttd2HgjwdaSya34juLS51rRYdTurK0Ok+Ho9Vs9T8UX2kaS0mow4X7cH7YHgf9h/8AZz8a
fH7xtZtr8mjmw0PwX4Itta0nQ9V+IHjnX7j7LoPhjSrzVW2KuxbvxD4jvNO0/XNT0TwTofifxHae
G9el0JtLuv8AOr/af/af+MX7X3xh8R/G743eIzr3i3Xdlnp9hZpNZ+GPBnhiznuZtG8E+CdGlubv
+w/Cuifa7prW0a5u9Q1HUbzVPEfiPU9c8V65r2vap+Q+J3irgvD6jQwOEw1LNOJMXTdfD4PEutHB
4TC89SlHGY+dGVGrVjVq0p0qeEw9ejVrezq1KmIw8I0XW/0U+gh9AHiD6XuYZlxVxJnGY8E+C/De
PeU5txHlKwFTiXiXPo4fC4yvw5wnTzGhjcFgauBwONwuMzPiHNMtzDAYJ4rBYPCZbm+JrY6OVfut
+0r/AMHJPx48X3Gu6D+zB8KfCHwi8NTDXtM0vxx8Qd3xB+JL27X8ieHPFem6JFJp3w/8IayNLWO4
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')
	#endregion
	$picturebox1.Location = '38, 44'
	$picturebox1.Name = 'picturebox1'
	$picturebox1.Size = '60, 60'
	$picturebox1.TabIndex = 7
	$picturebox1.TabStop = $False
	#
	# labelWindowsUpgrade
	#
	$labelWindowsUpgrade.Anchor = 'Left, Right'
	$labelWindowsUpgrade.AutoSize = $True
	$labelWindowsUpgrade.Font = 'Microsoft Sans Serif, 20.25pt, style=Bold'
	$labelWindowsUpgrade.ForeColor = 'Blue'
	$labelWindowsUpgrade.Location = '131, 57'
	$labelWindowsUpgrade.Name = 'labelWindowsUpgrade'
	$labelWindowsUpgrade.Size = '244, 37'
	$labelWindowsUpgrade.TabIndex = 6
	$labelWindowsUpgrade.Text = 'Windows Upgrade'
	$labelWindowsUpgrade.TextAlign = 'TopCenter'
	$labelWindowsUpgrade.UseCompatibleTextRendering = $True
	#
	# textHeader
	#
	$textHeader.BackColor = 'Blue'
	$textHeader.BorderStyle = 'None'
	$textHeader.Font = 'Microsoft Sans Serif, 20.25pt, style=Bold'
	$textHeader.ForeColor = 'White'
	$textHeader.Location = '-1, -1'
	$textHeader.Name = 'textHeader'
	$textHeader.Size = '516, 31'
	$textHeader.TabIndex = 5
	$textHeader.TextAlign = 'Center'
	#
	# readyToolDeferLbl
	#
	$readyToolDeferLbl.AutoSize = $True
	$readyToolDeferLbl.BackColor = 'Transparent'
	$readyToolDeferLbl.Font = 'Microsoft Sans Serif, 12pt'
	$readyToolDeferLbl.ForeColor = 'Blue'
	$readyToolDeferLbl.Location = '141, 298'
	$readyToolDeferLbl.Name = 'readyToolDeferLbl'
	$readyToolDeferLbl.Size = '75, 24'
	$readyToolDeferLbl.TabIndex = 4
	$readyToolDeferLbl.Text = 'Postones'
	$readyToolDeferLbl.UseCompatibleTextRendering = $True
	#
	# readyToolInfoTb
	#
	$readyToolInfoTb.BackColor = '250, 250, 250'
	$readyToolInfoTb.BorderStyle = 'None'
	$readyToolInfoTb.Font = 'Microsoft Sans Serif, 11.25pt'
	$readyToolInfoTb.ForeColor = 'Black'
	$readyToolInfoTb.Location = '12, 110'
	$readyToolInfoTb.Multiline = $True
	$readyToolInfoTb.Name = 'readyToolInfoTb'
	$readyToolInfoTb.ReadOnly = $True
	$readyToolInfoTb.Size = '491, 185'
	$readyToolInfoTb.TabIndex = 3
	$readyToolInfoTb.TextAlign = 'Center'
	#
	# readyToolStartbutton
	#
	$readyToolStartbutton.BackColor = 'Transparent'
	$readyToolStartbutton.FlatAppearance.BorderColor = '24, 68, 137'
	$readyToolStartbutton.FlatStyle = 'Flat'
	$readyToolStartbutton.Font = 'Microsoft Sans Serif, 10pt, style=Bold'
	$readyToolStartbutton.ForeColor = 'Black'
	$readyToolStartbutton.Location = '208, 349'
	$readyToolStartbutton.Name = 'readyToolStartbutton'
	$readyToolStartbutton.Size = '85, 37'
	$readyToolStartbutton.TabIndex = 0
	$readyToolStartbutton.Text = 'Start'
	$readyToolStartbutton.UseCompatibleTextRendering = $True
	$readyToolStartbutton.UseVisualStyleBackColor = $False
	$readyToolStartbutton.add_Click($readyToolStartbutton_Click)
	#
	# readyToolPostponeButton
	#
	$readyToolPostponeButton.BackColor = 'Transparent'
	$readyToolPostponeButton.FlatAppearance.BorderColor = '24, 68, 137'
	$readyToolPostponeButton.FlatStyle = 'Flat'
	$readyToolPostponeButton.Font = 'Microsoft Sans Serif, 10pt, style=Bold'
	$readyToolPostponeButton.ForeColor = 'Black'
	$readyToolPostponeButton.Location = '97, 349'
	$readyToolPostponeButton.Name = 'readyToolPostponeButton'
	$readyToolPostponeButton.Size = '85, 37'
	$readyToolPostponeButton.TabIndex = 1
	$readyToolPostponeButton.Text = 'Postpone'
	$readyToolPostponeButton.UseCompatibleTextRendering = $True
	$readyToolPostponeButton.UseVisualStyleBackColor = $False
	$readyToolPostponeButton.add_Click($readyToolPostponeButton_Click)
	$InPlaceUpgradeReadyTool.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $InPlaceUpgradeReadyTool.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$InPlaceUpgradeReadyTool.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$InPlaceUpgradeReadyTool.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $InPlaceUpgradeReadyTool.ShowDialog()

} #End Function

#Call the form
Show-InPlaceUpgrade-ReadyTool_psf | Out-Null
