# Schedule

## json-csv website
https://json-csv.com/

## 排班流程
- 先算出每個月的總點數
- 由資歷低的先算7, 6, 5, 4 點, 
- 如果超過，再從資深的開始減點,最低3點 
- 點數分配完後開始排班
- 每個人預不要什麼班就不要排
- 一個一個人去排入
- 不要有出現QOD的情況
- 假日最多兩班
- 星期五輪流上
- 如果點數不平均，則這個月記錄下來超過的點數，下個月再減回來

## 月分
建立每個月的月份map
- 計算每個月的總點數
- 星期五
- 星期六、日
- 國定假日
- 今天是什麼人值班
- 今天有幾點

## 醫師
### 住院醫師
- 每個人的點數統計
- 每個人會預班
- 不要禮拜幾


## 主治醫師
  - 計算點數(人工)
  - 指定的日期先排
  - 先排假日班
  - 想要的星期幾先排
  - 指定想排的特定天數
  - 不可以排不想要的班
  - 急診班排法；先排值班，值班的隔天不要排急診班
  - 每個月的點數，一般來說是兩點，從年資高的開始減
  
## how to use 



1. first create seeds.exs
2. run your seeds file to setup resident and attending
example
```elixir
resident_lists = [%{name: "Mike", doctor_id: 1234, level: 3, is_attending: false},]
vs_lists = [%{name: "Jordan", doctor_id: 4567, is_attending: true, ranking: 10},]
```
3. create this month exs file

```elixir
alias Schedule.Calculate
alias Schedule.Month

#set this month
#22 is ordinary day; and 29, 30, 31 are using human power to set up
Calculate.set_this_month(~D[2018-12-01], [], [~D[2018-12-22]], [~D[2018-12-29], ~D[2018-12-30], ~D[2018-12-31]])

#get all redident except some condition
#more than some level, id
Calculate.get_residents_from_db(1, 1234)

#get all attedning except some one you want to remove at first 
Calculate.get_attendings_from_db(41)

#setup holiday and points
#id, total points, holidays
Calculate.set_holiday_points(1406, 1, 0)
Calculate.set_holiday_points(1078, 2, 0)
Calculate.set_holiday_points(109, 5, 1)
Calculate.set_holiday_points(111, 3, 0)


#this month partial function
reserve = &Month.generate_reserve_list(2018, 12, &1)


#start setting up the reserve

Calculate.set_reserve(106, [2, 4], reserve.([14, 27, 28]))
Calculate.set_reserve(108, [1, 4], reserve.([28, 29]) ++
    Month.generate_continuous_reserve(~D[2018-12-01], ~D[2018-12-15])
)

Calculate.set_reserve(109, [], reserve.([7, 28]))
Calculate.set_reserve(111, [1, 2], reserve.([]))
Calculate.set_reserve(112, [5], reserve.([5, 7, 8 , 9, 12, 14, 19, 21, 28]))
Calculate.set_reserve(113, [], 
  Month.generate_continuous_reserve(~D[2018-12-15], ~D[2018-12-31])
)
Calculate.set_reserve(114, [], reserve.([]))
Calculate.set_reserve(115, [3, 4], reserve.([]))



#remove some attending due to hand-made setup
Calculate.remove_attendings([43, 75, 82])

#setup attending reserve
#attending_reserve(id, weekdays_reserve, reserve_days, duty_wish, weekday_wish) do

Calculate.attending_reserve(18,  [1, 3, 7], [], [])
Calculate.attending_reserve(34, [4, 7], [], [], [3])
Calculate.attending_reserve(50, [1, 3, 7], [], [], [])
Calculate.attending_reserve(53, [1, 4], [], [], [] )
Calculate.attending_reserve(54, [3, 7], reserve.([2, 28]), [], [6])
Calculate.attending_reserve(60, [4], [], [], [])
Calculate.attending_reserve(64, [1, 3], [], [], [7])
Calculate.attending_reserve(68, [5], reserve.([2, 16, 22, 28]), [], [6, 7])
Calculate.attending_reserve(76, [1,4,5, 6], [], [], [])
Calculate.attending_reserve(85, [3, 4, 7], reserve.([8, 9]), [], [] )
Calculate.attending_reserve(88, [3, 4], [], reserve.([1]), [])
Calculate.attending_reserve(90, [1, 2, 3], [], [], [])
Calculate.attending_reserve(91, [1, 7], [], [], [] )
Calculate.attending_reserve(93, [2, 3, 4, 7], [], [], [] )
Calculate.attending_reserve(95, [1, 2, 3], [], reserve.([9]), [])
Calculate.attending_reserve(97, [2, 7], [], [], [])
Calculate.attending_reserve(103, [1,2], [], [], [6])
Calculate.attending_reserve(117, [3, 4, 6, 7], [], [], [] )
Calculate.attending_reserve(101, [3, 5], [], [], [] )
Calculate.attending_reserve(118, [3, 4], [], [], [] )


#for terminal
alias Schedule.Calculate
month = Calculate.get_current_month
resident = Calculate.get_current_residents

#calculate resident

#uncomment when you run in the terminal

#Calculate.resident_result(1000, resident, month)
#Calculate.result_to_json
#Calculate.resident_to_json


#calcualte attending
#Calculate.set_max_points(month)
#attending = Calculate.get_current_attendings
#Calculate.attending_result(1000, attending, month)
#Calculate.result_to_json
#Calculate.attending_to_json
```
4. copy your result to json-csv website
