zmk-config for CCK_BALL (4x6)

## 关于CCK_BALL的滚轮编码器

### 使用修改过的zmk EC11驱动

该款键盘与zmk官方的EC11驱动并不完全适配，在借助其它单片机抓包其信号特征后，借助AI实现了对zmk官方EC11驱动的修改，能够优化该款键盘左右滚轮的使用体验。

使用方法如下。

#### 1、将zmk代码库指向修改后的代码库

只需要修改2行：将zmk指向修改过的zmk代码库（第4行）；另外zmk官方库是打了个tag，而fork代码库是个分支，因此第10行也要改成 `v0.3-branch`。

参考配置：
```yaml
manifest:
  remotes:
    - name: zmkfirmware
      url-base: https://github.com/imhy123
    - name: DoctorWangWang
      url-base: https://github.com/DoctorWangWang
  projects:
    - name: zmk
      remote: zmkfirmware
      revision: v0.3-branch
      import: app/west.yml
    - name: zmk-pmw3610-driver
      remote: DoctorWangWang
      revision: main
      
  self:
    path: config
```

#### 2、在`cck_ball.dtsi`中将encoder的`steps`改为24

也是修改两处，即左右encoder的steps改为24即可。
```
    /* encoders */
	left_encoder: encoder_left {
		compatible = "alps,ec11";
        status = "disabled";
		label = "LEFT_ENCODER";
		a-gpios = <&gpio0 29 (GPIO_ACTIVE_HIGH | GPIO_PULL_UP)>;
		b-gpios = <&gpio0 2 (GPIO_ACTIVE_HIGH | GPIO_PULL_UP)>;
		steps = <24>;
	};

	right_encoder: encoder_right {
		compatible = "alps,ec11";
        status = "disabled";
		label = "RIGHT_ENCODER";
		a-gpios = <&gpio0 29 (GPIO_ACTIVE_HIGH | GPIO_PULL_UP)>;
		b-gpios = <&gpio0 2 (GPIO_ACTIVE_HIGH | GPIO_PULL_UP)>;
		steps = <24>;
	};
```


> PS: 因为这个编码器每转动一格是发2个信号，所以在驱动里面加了`pulses-per-detent`的配置项，默认值即为2，因此这里不用显式定义（其它编码器如需修改则在`cck_ball.dtsi`的`left_encoder`、`right_encoder`中定义）。

### 附：EC11编码器的抓包

这款编码器转动一周是24个“咔哒”，每个咔哒（detent）发出2次信号。而且编码器在转动时信号会高频抖动"前进一步立刻退一步"(3→2→3→2…)。
所以想要编码器真正能用：
1. 需要在zmk的EC11驱动里面加 pulses-per-detent=2，表示收到2次连续信号时（±2）才发一格 delta；
2. 需要重新zmk的EC11驱动，处理高频的信号、并进行抖动过滤，这个编码器的抖动的时候信号间隔只有7–150 µs；


在ESP32上连接这款编码器做了一个抓包记录如下：
```
I (1727976) ENC: delta=1 pos=-40
I (1738966) ENC_ISR: t=+1738728831us prev=0 curr=1 step=1 accum=1
I (1738986) ENC_ISR: t=+1738749998us prev=1 curr=3 step=1 accum=2
I (1738986) ENC_ISR: t=+1738750007us prev=3 curr=1 step=-1 accum=-1
I (1738986) ENC_ISR: t=+1738750027us prev=1 curr=3 step=1 accum=0
I (1738996) ENC_ISR: t=+1738750034us prev=3 curr=1 step=-1 accum=-1
I (1738996) ENC_ISR: t=+1738750065us prev=1 curr=3 step=1 accum=0
I (1739006) ENC_ISR: t=+1738750143us prev=3 curr=1 step=-1 accum=-1
I (1739016) ENC_ISR: t=+1738750168us prev=1 curr=3 step=1 accum=0
I (1739016) ENC: delta=1 pos=-39
I (1739086) ENC_ISR: t=+1738844119us prev=3 curr=2 step=1 accum=1
I (1739086) ENC_ISR: t=+1738844132us prev=2 curr=3 step=-1 accum=0
I (1739086) ENC_ISR: t=+1738844234us prev=3 curr=2 step=1 accum=1
I (1739086) ENC_ISR: t=+1738844259us prev=2 curr=3 step=-1 accum=0
I (1739096) ENC_ISR: t=+1738844272us prev=3 curr=2 step=1 accum=1
I (1739096) ENC_ISR: t=+1738844291us prev=2 curr=3 step=-1 accum=0
I (1739106) ENC_ISR: t=+1738844298us prev=3 curr=2 step=1 accum=1
I (1739116) ENC_ISR: t=+1738844330us prev=2 curr=3 step=-1 accum=0
I (1739116) ENC_ISR: t=+1738844419us prev=3 curr=2 step=1 accum=1
I (1739126) ENC_ISR: t=+1738844430us prev=2 curr=3 step=-1 accum=0
I (1739126) ENC_ISR: t=+1738844440us prev=3 curr=2 step=1 accum=1
I (1739136) ENC_ISR: t=+1738844475us prev=2 curr=3 step=-1 accum=0
I (1739136) ENC_ISR: t=+1738844484us prev=3 curr=2 step=1 accum=1
I (1739146) ENC_ISR: t=+1738844498us prev=2 curr=3 step=-1 accum=0
I (1739156) ENC_ISR: t=+1738844511us prev=3 curr=2 step=1 accum=1
I (1739156) ENC_ISR: t=+1738844525us prev=2 curr=3 step=-1 accum=0
I (1739166) ENC_ISR: t=+1738844532us prev=3 curr=2 step=1 accum=1
I (1739166) ENC_ISR: t=+1738844558us prev=2 curr=3 step=-1 accum=0
I (1739176) ENC_ISR: t=+1738844582us prev=3 curr=2 step=1 accum=1
I (1739186) ENC_ISR: t=+1738844629us prev=2 curr=3 step=-1 accum=0
I (1739186) ENC_ISR: t=+1738844668us prev=3 curr=2 step=1 accum=1
I (1739196) ENC_ISR: t=+1738844680us prev=2 curr=3 step=-1 accum=0
I (1739196) ENC_ISR: t=+1738844724us prev=3 curr=2 step=1 accum=1
I (1739206) ENC_ISR: t=+1738844847us prev=2 curr=3 step=-1 accum=0
I (1739206) ENC_ISR: t=+1738844877us prev=3 curr=2 step=1 accum=1
I (1739216) ENC_ISR: t=+1738844893us prev=2 curr=3 step=-1 accum=0
I (1739226) ENC_ISR: t=+1738844900us prev=3 curr=2 step=1 accum=1
I (1739226) ENC_ISR: t=+1738845043us prev=2 curr=3 step=-1 accum=0
I (1739236) ENC_ISR: t=+1738845058us prev=3 curr=2 step=1 accum=1
I (1739236) ENC_ISR: t=+1738845145us prev=2 curr=3 step=-1 accum=0
I (1739246) ENC_ISR: t=+1738845159us prev=3 curr=2 step=1 accum=1
I (1739256) ENC_ISR: t=+1738845272us prev=2 curr=3 step=-1 accum=0
I (1739256) ENC_ISR: t=+1738845287us prev=3 curr=2 step=1 accum=1
I (1739266) ENC_ISR: t=+1738885201us prev=2 curr=0 step=1 accum=2
I (1739266) ENC_ISR: t=+1738885224us prev=0 curr=2 step=-1 accum=-1
I (1739276) ENC_ISR: t=+1738885232us prev=2 curr=0 step=1 accum=0
I (1739286) ENC: delta=1 pos=-38
I (1739656) ENC_ISR: t=+1739422835us prev=0 curr=1 step=1 accum=1
I (1739686) ENC_ISR: t=+1739452290us prev=1 curr=3 step=1 accum=2
I (1739686) ENC_ISR: t=+1739452305us prev=3 curr=1 step=-1 accum=-1
I (1739696) ENC_ISR: t=+1739452442us prev=1 curr=3 step=1 accum=0
I (1739696) ENC_ISR: t=+1739452449us prev=3 curr=1 step=-1 accum=-1
I (1739706) ENC_ISR: t=+1739452455us prev=1 curr=3 step=1 accum=0
I (1739706) ENC_ISR: t=+1739452464us prev=3 curr=1 step=-1 accum=-1
I (1739716) ENC_ISR: t=+1739452492us prev=1 curr=3 step=1 accum=0
I (1739716) ENC_ISR: t=+1739452505us prev=3 curr=1 step=-1 accum=-1
I (1739726) ENC_ISR: t=+1739452591us prev=1 curr=3 step=1 accum=0
I (1739736) ENC_ISR: t=+1739452597us prev=3 curr=1 step=-1 accum=-1
I (1739736) ENC_ISR: t=+1739452629us prev=1 curr=3 step=1 accum=0
I (1739746) ENC_ISR: t=+1739452646us prev=3 curr=1 step=-1 accum=-1
I (1739746) ENC_ISR: t=+1739452652us prev=1 curr=3 step=1 accum=0
I (1739756) ENC_ISR: t=+1739452659us prev=3 curr=1 step=-1 accum=-1
I (1739766) ENC_ISR: t=+1739452677us prev=1 curr=3 step=1 accum=0
I (1739766) ENC_ISR: t=+1739452684us prev=3 curr=1 step=-1 accum=-1
I (1739776) ENC_ISR: t=+1739452700us prev=1 curr=3 step=1 accum=0
I (1739776) ENC_ISR: t=+1739452707us prev=3 curr=1 step=-1 accum=-1
I (1739786) ENC_ISR: t=+1739452722us prev=1 curr=3 step=1 accum=0
I (1739786) ENC_ISR: t=+1739452787us prev=3 curr=1 step=-1 accum=-1
I (1739796) ENC_ISR: t=+1739452801us prev=1 curr=3 step=1 accum=0
I (1739806) ENC_ISR: t=+1739452815us prev=3 curr=1 step=-1 accum=-1
I (1739806) ENC_ISR: t=+1739452829us prev=1 curr=3 step=1 accum=0
I (1739816) ENC_ISR: t=+1739452845us prev=3 curr=1 step=-1 accum=-1
I (1739816) ENC_ISR: t=+1739452862us prev=1 curr=3 step=1 accum=0
I (1739826) ENC_ISR: t=+1739452868us prev=3 curr=1 step=-1 accum=-1
I (1739836) ENC_ISR: t=+1739452882us prev=1 curr=3 step=1 accum=0
I (1739836) ENC_ISR: t=+1739452899us prev=3 curr=1 step=-1 accum=-1
I (1739846) ENC_ISR: t=+1739453074us prev=1 curr=3 step=1 accum=0
I (1739846) ENC_ISR: t=+1739453080us prev=3 curr=1 step=-1 accum=-1
I (1739856) ENC_ISR: t=+1739453137us prev=1 curr=3 step=1 accum=0
I (1739866) ENC_ISR: t=+1739453143us prev=3 curr=1 step=-1 accum=-1
I (1739866) ENC_ISR: t=+1739453254us prev=1 curr=3 step=1 accum=0
I (1739876) ENC_ISR: t=+1739453265us prev=3 curr=1 step=-1 accum=-1
I (1739876) ENC_ISR: t=+1739453348us prev=1 curr=3 step=1 accum=0
I (1739886) ENC_ISR: t=+1739453359us prev=3 curr=1 step=-1 accum=-1
I (1739896) ENC_ISR: t=+1739453413us prev=1 curr=3 step=1 accum=0
I (1739896) ENC_ISR: t=+1739453420us prev=3 curr=1 step=-1 accum=-1
I (1739906) ENC_ISR: t=+1739453495us prev=1 curr=3 step=1 accum=0
I (1739906) ENC_ISR: t=+1739559059us prev=3 curr=2 step=1 accum=1
I (1739916) ENC_ISR: t=+1739622201us prev=2 curr=0 step=1 accum=2
I (1739916) ENC: delta=1 pos=-37
I (1739926) ENC: delta=1 pos=-36
I (1740446) ENC_ISR: t=+1740211873us prev=0 curr=1 step=1 accum=1
I (1740446) ENC_ISR: t=+1740211881us prev=1 curr=0 step=-1 accum=0
I (1740446) ENC_ISR: t=+1740211900us prev=0 curr=1 step=1 accum=1
I (1740456) ENC_ISR: t=+1740211915us prev=1 curr=0 step=-1 accum=0
I (1740466) ENC_ISR: t=+1740211938us prev=0 curr=1 step=1 accum=1
I (1740486) ENC_ISR: t=+1740245576us prev=1 curr=3 step=1 accum=2
I (1740486) ENC: delta=1 pos=-35
I (1743496) ENC_ISR: t=+1743262941us prev=3 curr=2 step=1 accum=1
I (1743506) ENC_ISR: t=+1743270230us prev=2 curr=0 step=1 accum=2
I (1743506) ENC: delta=1 pos=-34
I (1743976) ENC_ISR: t=+1743739666us prev=0 curr=1 step=1 accum=1
I (1743996) ENC_ISR: t=+1743756467us prev=1 curr=3 step=1 accum=2
I (1743996) ENC: delta=1 pos=-33
I (1744146) ENC_ISR: t=+1743910964us prev=3 curr=2 step=1 accum=1
I (1744376) ENC_ISR: t=+1744136889us prev=2 curr=0 step=1 accum=2
I (1744376) ENC: delta=1 pos=-32
I (1744646) ENC_ISR: t=+1744406640us prev=0 curr=1 step=1 accum=1
I (1744646) ENC_ISR: t=+1744406682us prev=1 curr=0 step=-1 accum=0
I (1744646) ENC_ISR: t=+1744407073us prev=0 curr=1 step=1 accum=1
I (1744666) ENC_ISR: t=+1744423903us prev=1 curr=3 step=1 accum=2
I (1744666) ENC: delta=1 pos=-31
I (1744796) ENC_ISR: t=+1744556046us prev=3 curr=2 step=1 accum=1
I (1744806) ENC_ISR: t=+1744564952us prev=2 curr=0 step=1 accum=2
I (1744806) ENC: delta=1 pos=-30
I (1745216) ENC_ISR: t=+1744979066us prev=0 curr=1 step=1 accum=1
I (1745216) ENC_ISR: t=+1744979076us prev=1 curr=0 step=-1 accum=0
I (1745216) ENC_ISR: t=+1744979086us prev=0 curr=1 step=1 accum=1
I (1745226) ENC_ISR: t=+1744993279us prev=1 curr=3 step=1 accum=2
I (1745226) ENC: delta=1 pos=-29
I (1745596) ENC_ISR: t=+1745354435us prev=3 curr=2 step=1 accum=1
I (1745616) ENC_ISR: t=+1745374531us prev=2 curr=0 step=1 accum=2
I (1745616) ENC: delta=1 pos=-28
I (1746046) ENC_ISR: t=+1745805157us prev=0 curr=1 step=1 accum=1
I (1746046) ENC_ISR: t=+1745805164us prev=1 curr=0 step=-1 accum=0
I (1746046) ENC_ISR: t=+1745805179us prev=0 curr=1 step=1 accum=1
I (1746046) ENC_ISR: t=+1745805190us prev=1 curr=0 step=-1 accum=0
I (1746056) ENC_ISR: t=+1745805197us prev=0 curr=1 step=1 accum=1
I (1746056) ENC_ISR: t=+1745823200us prev=1 curr=3 step=1 accum=2
I (1746066) ENC: delta=1 pos=-27
```