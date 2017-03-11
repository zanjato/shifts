set nocount on;
go
declare @bg date='20170227';
declare @fn date=dateadd(dd,4,@bg);
with
  wk as(
    select
      dateadd(dd,row_number()over(order by(select 0))-2,@bg)dt,
      case row_number()over(order by(select 0))
        when 1 then'вс'
        when datediff(dd,@bg,@fn)+2 then'пт'
        when datediff(dd,@bg,@fn)+3 then'сб'
        when 2 then'пн'
        else'рд'
      end dn
    from master..spt_values cross join master..spt_values a
    order by row_number()over(order by(select 0))
      offset 0 rows fetch first datediff(dd,@bg,@fn)+3 rows only
  ),
  pt as(--personnel transportation
    select wk.dt,pl.nm,
      case pl.sf
        when'Н'then
          iif(tr.n=1,dateadd(mi,iif(wk.dn='вс',0,-15),cast(pl.ntp as time(0))),
                     iif(wk.dn='пн','7:30','7:15'))
--          case tr.n
--            when 2 then iif(wk.dn='пн','7:30','7:15')
--            else dateadd(mi,iif(wk.dn='вс',0,-15),cast(pl.ntp as time(0)))
--          end
        when'У'then cast(pl.mtp as time(0))
        when'В'then'0:05'
      end tm,'к '+iif(tr.n=1,'месту проживания','работе')pc,pl.sf,wk.dn
    from(values('Ага С.В.','П',null,null,null,null),
               ('Вид И.В.','У','23:50','6:50',1,1),
               ('Урт А.В.','В','23:45','6:45',1,1),
               ('Зоб К.В.','Д','23:45','6:30',1,1),
               ('Маз С.В.','В','23:50','6:45',1,1),
               ('Фок С.Л.','Н','23:45','6:45',1,1),
               ('Чес Л.О.','У','23:45','6:40',1,1)
        )pl(nm,sf,ntp,mtp,mtr,ntr)
    cross join(values(1),(2))tr(n) -- к 1-месту проживания, 2-работе
    cross join wk
    where(pl.sf='Н' and((tr.n=1 and pl.ntp is not null and
                         wk.dn in('вс','пн','рд'))or
                        (tr.n=2 and pl.mtr is not null and
                         wk.dn in('пн','рд','пт'))))or
         (pl.sf='У' and tr.n=1 and pl.mtp is not null and
          wk.dn in('пн','рд','пт'))or
         (pl.sf='В' and tr.n=2 and pl.ntr is not null and
          (wk.dn in('рд','сб')or(@bg<@fn and wk.dn='пт')))
  )
select ltrim(str(row_number()over(partition by dt order by tm,nm)))+'.'nn,
  nm,cast(tm as char(5))+' ('+pc+')'tp,convert(char,dt,104)dt,sf,dn
from pt order by pt.dt,tm,nm;