# Text LCD 파트 (디지털 시계 팀 프로젝트)

16x2 Text LCD에 **모드**와 **알람 정보(알람 시각, On/Off)**를 표시하고,
PSD와 연동해서 **알람 꺼짐 / 다음 알람 / 타이머 일시정지** 상태를 보여줍니다.
팀 `top_lcd.v`에 이미 연결되어 있습니다.

## 파일 구성 (모두 팀 폴더 맨 바깥에 둠)

| 파일 | 역할 |
|---|---|
| `top_lcd.v` | 팀 top.v (alarm&psd 반영본) 복사본 + LCD 연결 (top.v 는 그대로) |
| `text_lcd_top.v` | LCD 파트 최상위 |
| `lcd_formatter.v` | 시계 상태 → LCD 문자열 |
| `text_lcd_ctrl.v` | LCD 드라이버 (초기화 + 글자 쓰기) |
| `blink_gen.v` | 설정 칸 깜빡임용 1Hz 신호 |
| `tb_text_lcd.v` | 가상 LCD 테스트벤치 |
| `pins_team.tcl` | 전체 핀 설정 |

## 화면

| 상황 | 1번째 줄 | 2번째 줄 |
|---|---|---|
| 시계 동작 (mode 0) | `NORMAL  23:07:12` | `AL 07:30:00 ON  ` |
| 시계 설정 (mode 1) | `CLK SET 23:07:12` | `AL 07:30:00 ON  ` |
| 알람 설정 (mode 2) | `ALM SET 07:30:00` | `AL 07:30:00 ON  ` |
| 타이머 설정 (mode 3) | `TMR SET 00:03:00` | `STATUS: STOP    ` |
| 타이머 동작 (mode 4) | `TIMER   00:02:59` | `STATUS: RUN     ` |
| 알람 울리는 중 | ` ALARM RINGING! ` | `WAVE HAND->OFF  ` |
| 손 대서 알람 꺼짐 (2초) | ` ALARM STOPPED  ` | (빈 줄) |
| 시계 동작 중 손 대기 (뗀 뒤 3초) | `NEXT AL 07:30:00` | `IN 08h 23m      ` |
| 위와 같은데 알람 OFF | `NO ALARM SET    ` | (빈 줄) |

- 설정 모드에서는 선택한 칸(시/분/초)이 깜빡입니다.
- 손이 감지되면 2번째 줄 마지막 칸에 `*`가 표시됩니다.

## top_lcd.v 에서 추가된 점 (팀 top.v 기준)

1. 이 보드는 7-segment 와 Text LCD 가 **같은 핀**을 씀 → `i_sw[5]` 로 선택 (0 = 7-segment, 1 = LCD)
   - LCD D7~D0 = `o_seg[0]~[7]` 핀, LCD E/RW/RS = `o_seg_enb[3]/[4]/[5]` 핀
   - LCD 로 바꿀 때마다 LCD 를 처음부터 초기화
2. `text_lcd_top` 연결 (PSD 감지는 팀 top.v 의 `psd_near` 를 그대로 사용)
3. 그 외 동작(알람·타이머·PSD)은 팀 top.v 와 같음

## 핀

`pins_team.tcl` 에 전체 핀이 들어 있음 (팀 핀 표 + PSD용 ADC 핀 4개). LCD 용 핀은 따로 없음.

## 시뮬레이션 (팀 폴더에서)

```bash
iverilog -o sim tb_text_lcd.v text_lcd_top.v lcd_formatter.v text_lcd_ctrl.v
vvp sim
```
