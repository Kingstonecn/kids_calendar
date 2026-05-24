import 'dart:math';

/// 农历查表转换工具
/// 基于农历数据查表法,支持 1901-2100 年公历转农历
class LunarCalendar {
  // 农历数据: 每个月前12位表示每月大小月(1=30天,0=29天), 第13-16位表示闰月(0=无闰月)
  // 数据来源: 中国科学院紫金山天文台
  static const List<int> lunarInfo = [
    0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2, //1900-1909
    0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977, //1910-1919
    0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, //1920-1929
    0x06566, 0x0d4a0, 0x0ea50, 0x16a95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950, //1930-1939
    0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, //1940-1949
    0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0, //1950-1959
    0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, //1960-1969
    0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6, //1970-1979
    0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570, //1980-1989
    0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x05ac0, 0x0ab60, 0x096d5, 0x092e0, //1990-1999
    0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, //2000-2009
    0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930, //2010-2019
    0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530, //2020-2029
    0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, //2030-2039
    0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0, //2040-2049
    0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06aa0, 0x1a6c4, 0x0aae0, //2050-2059
    0x092e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4, //2060-2069
    0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0, //2070-2079
    0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160, //2080-2089
    0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a4d0, 0x0d150, 0x0f252, //2090-2099
    0x0d520, //2100
  ];

  static const List<String> heavenlyStems = ['甲','乙','丙','丁','戊','己','庚','辛','壬','癸'];
  static const List<String> earthlyBranches = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];
  static const List<String> zodiacs = ['鼠','牛','虎','兔','龙','蛇','马','羊','猴','鸡','狗','猪'];
  static const List<String> lunarMonthNames = [
    '正月','二月','三月','四月','五月','六月','七月','八月','九月','十月','冬月','腊月'
  ];
  static const List<String> lunarDayNames = [
    '初一','初二','初三','初四','初五','初六','初七','初八','初九','初十',
    '十一','十二','十三','十四','十五','十六','十七','十八','十九','二十',
    '廿一','廿二','廿三','廿四','廿五','廿六','廿七','廿八','廿九','三十'
  ];

  /// 获取农历年是否有闰月
  static int leapMonth(int year) {
    if (year < 1900 || year > 2100) return 0;
    return lunarInfo[year - 1900] & 0xf;
  }

  /// 获取农历年闰月天数
  static int leapDays(int year) {
    if (year < 1900 || year > 2100) return 0;
    return (lunarInfo[year - 1900] & 0xf000) == 0 ? 29 : 30;
  }

  /// 获取农历年某月的天数
  static int monthDays(int year, int month) {
    if (year < 1900 || year > 2100 || month < 1 || month > 12) return 29;
    return (lunarInfo[year - 1900] & (0x10000 >> month)) == 0 ? 29 : 30;
  }

  /// 获取农历年的总天数
  static int yearDays(int year) {
    if (year < 1900 || year > 2100) return 0;
    int sum = 348; // 12 * 29
    for (int i = 0x8000; i > 0x8; i >>= 1) {
      sum += (lunarInfo[year - 1900] & i) == 0 ? 0 : 1;
    }
    return sum + leapDays(year);
  }

  /// 获取农历新年（正月初一）对应的公历日期（儒略日）
  static int _lunarNewYearOffset(int year) {
    int sum = 0;
    for (int i = 1900; i < year; i++) {
      sum += yearDays(i);
    }
    return sum;
  }

  /// 公历转农历
  /// 返回: {year, month, day, isLeap, monthName, dayName, ganZhi, zodiac}
  static Map<String, dynamic> solarToLunar(int year, int month, int day) {
    // 以1900年正月初一(公历1900-01-31)为基准
    final baseDate = DateTime(1900, 1, 31);
    final targetDate = DateTime(year, month, day);
    final offset = targetDate.difference(baseDate).inDays;

    if (offset < 0) {
      return {'year': 0, 'month': 0, 'day': 0, 'isLeap': false, 'monthName': '', 'dayName': '', 'ganZhi': '', 'zodiac': ''};
    }

    int lunarYear;
    int daysCount = 0;

    // 确定农历年
    for (lunarYear = 1900; lunarYear < 2101; lunarYear++) {
      final yd = yearDays(lunarYear);
      if (daysCount + yd > offset) break;
      daysCount += yd;
    }

    if (lunarYear > 2100) {
      return {'year': 0, 'month': 0, 'day': 0, 'isLeap': false, 'monthName': '', 'dayName': '', 'ganZhi': '', 'zodiac': ''};
    }

    int lunarMonth;
    int remaining = offset - daysCount;
    final leap = leapMonth(lunarYear);
    bool isLeap = false;

    // 确定农历月
    for (lunarMonth = 1; lunarMonth <= 12; lunarMonth++) {
      if (leap > 0 && lunarMonth == leap + 1) {
        // 先处理闰月
        final ld = leapDays(lunarYear);
        if (remaining < ld) {
          isLeap = true;
          break;
        }
        remaining -= ld;
      }
      final md = monthDays(lunarYear, lunarMonth);
      if (remaining < md) break;
      remaining -= md;
    }

    if (lunarMonth > 12) {
      lunarMonth = 12;
      remaining = 29; // fallback
    }

    final lunarDay = remaining + 1;

    // 计算干支和生肖
    final ganZhi = _getGanZhi(lunarYear);
    final zodiac = zodiacs[(lunarYear - 4) % 12];

    String monthName = '';
    if (isLeap) {
      monthName = '闰${lunarMonthNames[lunarMonth - 1]}';
    } else {
      monthName = lunarMonthNames[lunarMonth - 1];
    }

    final dayName = lunarDayNames[lunarDay - 1];

    return {
      'year': lunarYear,
      'month': lunarMonth,
      'day': lunarDay,
      'isLeap': isLeap,
      'monthName': monthName,
      'dayName': dayName,
      'ganZhi': ganZhi,
      'zodiac': zodiac,
    };
  }

  static String _getGanZhi(int year) {
    final stem = heavenlyStems[(year - 4) % 10];
    final branch = earthlyBranches[(year - 4) % 12];
    return '$stem$branch年';
  }

  /// 获取简洁农历字符串, 如 "三月十五"
  static String simpleLunar(int year, int month, int day) {
    final result = solarToLunar(year, month, day);
    if (result['month'] == 0) return '';
    return '${result['monthName']}${result['dayName']}';
  }

  /// 判断是否为农历节日
  static String? getLunarFestival(int year, int month, int day) {
    final lunar = solarToLunar(year, month, day);
    final m = lunar['month'] as int;
    final d = lunar['day'] as int;

    if (m == 1 && d == 1) return '春节';
    if (m == 1 && d == 15) return '元宵节';
    if (m == 5 && d == 5) return '端午节';
    if (m == 7 && d == 7) return '七夕节';
    if (m == 7 && d == 15) return '中元节';
    if (m == 8 && d == 15) return '中秋节';
    if (m == 9 && d == 9) return '重阳节';
    if (m == 12 && d == 30) return '除夕';
    if (m == 12 && d == 29) {
      // 腊月小月时29为除夕
      final days = monthDays(lunar['year'] as int, 12);
      if (days == 29) return '除夕';
    }
    return null;
  }

  /// 获取某月所有日期的农历信息 (用于日历渲染)
  static List<Map<String, dynamic>> getMonthLunarInfo(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final result = <Map<String, dynamic>>[];
    for (int day = 1; day <= daysInMonth; day++) {
      final lunar = solarToLunar(year, month, day);
      final festival = getLunarFestival(year, month, day);
      result.add({
        'day': day,
        'lunarDay': lunar['dayName'],
        'lunarMonth': lunar['monthName'],
        'festival': festival,
        'isLeap': lunar['isLeap'],
      });
    }
    return result;
  }
}
