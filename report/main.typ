#set text(font: "Times New Roman", 13pt)
#set page(
  numbering: "1",
  number-align: right,
  footer: context {
    set align(center)
    if counter(page).get() == (1,) or counter(page).get() == (2,) {} else {
      counter(page).display()
    }
  },
)
#set par(
  justify: true,
  leading: 1em
)

#set heading(numbering: "1.")
#show heading.where(level: 1): it => {
  if it.body == [Mục lục] {
    [
      Mục lục
      #linebreak()
    ]
  } else if it.body == [Danh mục hình] {
    [
      Danh mục hình
      #linebreak()
    ]
  } else {
    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: table)).update(0)
    counter(figure.where(kind: raw)).update(0)

    [
      CHƯƠNG #context { counter(heading).display("1") }: #text(upper(it.body))
    ]

    counter(it.location()).step()
  }
}

#show link: underline
#show figure.caption: it => {
  let fig_num = context {
    let chapt = counter(heading).at(it.location()).at(0)
    let num = it.counter.at(it.location()).at(0)
    numbering("1.1", chapt, num)
  }

  if (it.kind == image) {
    [Hình #fig_num: #(it.body)]
  } else if (it.kind == raw) {
    [Đoạn mã #fig_num: #(it.body)]
  } else if (it.kind == table) {
    [Bảng #fig_num: #(it.body)]
  }
}

#set ref(supplement: it => {
  if it.func() == figure {
    "Hình"
  } else {
    it.supplement
  }
})

#show outline.entry.where(
  element: figure.where(kind: image)
): it => {
  let loc = it.element.location()
  
  let chapt = counter(heading).at(loc).at(0)
  let num = counter(figure.where(kind: image)).at(loc).at(0)
  
  let fig_label = [#chapt.#num]

  link(loc)[
    Hình #fig_label: #it.element.caption.body
    #box(width: 1fr, repeat[ . ])
    #it.page
  ]
}

#include "cover.typ"
#pagebreak()

#outline(title: [Mục lục])
#pagebreak()

#outline(
  title: [Danh mục hình],
  target: figure.where(kind: image)
)
#pagebreak()

#include "ch1.typ"
#pagebreak()
#include "ch2.typ"
#pagebreak()
#include "ch3.typ"
#pagebreak()
#include "ch4.typ"
#pagebreak()
#include "ch5.typ"
#pagebreak()