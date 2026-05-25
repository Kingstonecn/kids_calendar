/// 农历查表转换工具
/// 基于农历数据查表法, 支持 1901-2100 年公历转农历
class LunarCalendar {
  // 农历数据: 低16位中 bits 4-15 表示各月大小月(1=30天,0=29天),
  // bits 0-3 表示闰月(0=无闰月), bit 16 表示闰月天数(1=30,0=29)
  static const List<int> lunarInfo = [
    0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
    0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
    0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970,
    0x06566, 0x0d4a0, 0x0ea50, 0x16a95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950,
    0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557,
    0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0,
    0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0,
    0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6,
    0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570,
    0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x05ac0, 0x0ab60, 0x096d5, 0x092e0,
    0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5,
    0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930,
    0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530,
    0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45,
    0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0,
    0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06aa0, 0x1a6c4, 0x0aae0,
    0x092e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4,
    0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0,
    0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160,
    0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a4d0, 0x0d150, 0x0f252,
    0x0d520,
  ];

  static const List<String> lunarMonthNames = [
    '正月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '冬月', '腊月',
  ];
  static const List<String> lunarDayNames = [
    '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
    '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
    '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十',
  ];

  /// 获取农历年是否有闰月 (0=无闰月)
  static int leapMonth(int year) {
    if (year < 1900 || year > 2100) return 0;
    return lunarInfo[year - 1900] & 0xf;
  }

  /// 获取农历年闰月天数 (仅当有闰月时有效)
  static int leapDays(int year) {
    if (year < 1900 || year > 2100) return 0;
    // bit 16 表示闰月天数 (0=29天, 1=30天)
    return (lunarInfo[year - 1900] & 0x10000) == 0 ? 29 : 30;
  }

  /// 获取农历年某月的天数
  static int monthDays(int year, int month) {
    if (year < 1900 || year > 2100 || month < 1 || month > 12) return 29;
    return (lunarInfo[year - 1900] & (0x10000 >> month)) == 0 ? 29 : 30;
  }

  /// 获取农历年的总天数 (含闰月)
  static int yearDays(int year) {
    if (year < 1900 || year > 2100) return 0;
    int sum = 348; // 12 * 29
    for (int i = 0x8000; i > 0x8; i >>= 1) {
      sum += (lunarInfo[year - 1900] & i) == 0 ? 0 : 1;
    }
    // 只在有闰月时才加闰月天数
    return sum + (leapMonth(year) > 0 ? leapDays(year) : 0);
  }

  /// 公历转农历
  static Map<String, dynamic> solarToLunar(int year, int month, int day) {
    final baseDate = DateTime(1900, 1, 31);
    final targetDate = DateTime(year, month, day);
    final offset = targetDate.difference(baseDate).inDays;

    if (offset < 0) {
      return {
        'year': 0, 'month': 0, 'day': 0, 'isLeap': false,
        'monthName': '', 'dayName': '',
      };
    }

    int lunarYear;
    int daysCount = 0;

    for (lunarYear = 1900; lunarYear < 2101; lunarYear++) {
      final yd = yearDays(lunarYear);
      if (daysCount + yd > offset) break;
      daysCount += yd;
    }

    if (lunarYear > 2100) {
      return {
        'year': 0, 'month': 0, 'day': 0, 'isLeap': false,
        'monthName': '', 'dayName': '',
      };
    }

    int remaining = offset - daysCount;
    final leap = leapMonth(lunarYear);
    bool isLeap = false;
    int lunarMonth;

    for (lunarMonth = 1; lunarMonth <= 12; lunarMonth++) {
      if (leap > 0 && lunarMonth == leap + 1) {
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
      remaining = 29;
    }

    final lunarDay = remaining + 1;

    final monthName = isLeap
        ? '闰${lunarMonthNames[lunarMonth - 1]}'
        : lunarMonthNames[lunarMonth - 1];
    final dayName = lunarDayNames[lunarDay - 1];

    return {
      'year': lunarYear,
      'month': lunarMonth,
      'day': lunarDay,
      'isLeap': isLeap,
      'monthName': monthName,
      'dayName': dayName,
    };
  }

  /// 获取简洁农历字符串, 如 "三月十五"
  static String simpleLunar(int year, int month, int day) {
    final result = solarToLunar(year, month, day);
    if (result['month'] == 0) return '';
    return '${result['monthName']}${result['dayName']}';
  }

  /// 获取法定节假日名称
  /// 包括: 元旦、春节、清明节、劳动节、端午节、中秋节、国庆节
  static String? getLegalHoliday(int year, int month, int day) {
    // 公历固定日期节假日
    if (month == 1 && day == 1) return '元旦';
    if (month == 4 && _isQingming(year, day)) return '清明节';
    if (month == 5 && day == 1) return '劳动节';
    if (month == 10 && day == 1) return '国庆节';

    // 农历节假日 (春节从除夕到正月初六, 端午/中秋为单日)
    final lunar = solarToLunar(year, month, day);
    final m = lunar['month'] as int;
    final d = lunar['day'] as int;
    final ly = lunar['year'] as int;

    if (m == 12 && d == 30) return '春节'; // 除夕
    if (m == 12 && d == 29) {
      final days = monthDays(ly, 12);
      if (days == 29) return '春节'; // 小月29为除夕
    }
    if (m == 1 && d >= 1 && d <= 7) return '春节'; // 正月初一至初七
    if (m == 5 && d == 5) return '端午节';
    if (m == 8 && d == 15) return '中秋节';

    return null;
  }

  /// 判断清明节日期 (4月4日或5日, 因年而异)
  static bool _isQingming(int year, int day) {
    // 清明节日期 (4月4日或5日)
    // 已知年份的清明节:
    // 2020-04-04, 2021-04-04, 2022-04-05, 2023-04-05,
    // 2024-04-04, 2025-04-04, 2026-04-05, 2027-04-05,
    // 2028-04-04, 2029-04-04, 2030-04-05, 2031-04-05
    const qingmingApr4 = {
      2020, 2021, 2024, 2025, 2028, 2029, 2032, 2033, 2036, 2037,
    };
    if (day == 4 && qingmingApr4.contains(year)) return true;
    if (day == 5 && !qingmingApr4.contains(year)) return true;
    return false;
  }
}
