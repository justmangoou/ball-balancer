#set text(font: "Times New Roman", 13pt)
#set list(indent: 3em)

#set page(
  numbering: "1",
  number-align: right,
  paper: "a4",
  footer: context {
    set align(center)
    
    let p = counter(page).get().at(0)
    if p > 1 { counter(page).display() }
  },
)

#set par(
  justify: true,
  leading: 1em,
  first-line-indent: 2em
)

// ===== Heading ======
#let force-indent = {
  par(text(size: 0pt, ""))
  v(-1.2em)
}
#set heading(numbering: "1.")

#show heading.where(level: 1): it => {
  let front_matter_text = ([COVER], [Mục lục], [Danh mục hình], [Danh mục bảng], [Danh mục ký hiệu và từ viết tắt])

  if front_matter_text.contains(it.body) {
    set align(center)
    it.body
    v(0.5em)
  } else {
    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: table)).update(0)
    counter(figure.where(kind: raw)).update(0)

    [
      CHƯƠNG #context { counter(heading).display("1") }: 
      #text(upper(it.body))
      #v(0.5em)
    ]
  }
  force-indent
}

#show heading.where(level: 2): it => [ #it #v(0.1em) #force-indent ]
#show heading.where(level: 3): it => [ #it #v(0.2em) #force-indent ]
#show heading.where(level: 4): it => [ #it #v(0.2em) #force-indent ]

// ===== Figure =====
#show figure.caption: it => {
  context {
    let loc = it.location()
    let ch = counter(heading).at(loc).at(0)
    
    let num = counter(figure.where(kind: it.kind)).at(loc).at(0)
    let fig_num = numbering("1.1", ch, num)

    if it.kind == image {
      [#emph[Hình #fig_num]: #it.body]
    } else if it.kind == raw {
      [Đoạn mã #fig_num: #it.body]
    } else if it.kind == table {
      [Bảng #fig_num: #it.body]
    }
  }
}

#set ref(supplement: it => {
  if it.func() == figure {
    emph[Hình]
  } else {
    it.supplement
  }
})

#show figure.where(kind: table).or(figure.where(kind: raw)): it => [
  #set align(left)
  #set par(first-line-indent: 0pt)
  #v(it.gap)
  #it.caption
  #it.body
]

// ===== Outline =====
#show outline.entry: it => {
  let element = it.element
  let loc = element.location()
  let prefix = it.prefix()

  if it.element.func() == figure {
    let ch = counter(heading).at(loc).at(0)
    let num = counter(figure.where(kind: element.kind)).at(loc).at(0)

    if (element.kind == image) { prefix = [Hình #ch.#num] }
    else if (element.kind == raw) { prefix = [Đoạn mã #ch.#num] } 
    else if (element.kind == table) { prefix = [Bảng #ch.#num] }
  }

  link(loc, it.indented(prefix, it.inner()))
}

// ===== Cover ===== 
#include "cover.typ"
#pagebreak()

#outline(title: [Mục lục])
#pagebreak()

#heading(numbering: none)[Danh mục hình]
#outline(
  title: none,
  target: figure.where(kind: image)
)
#pagebreak()

#heading(numbering: none)[Danh mục bảng]
#outline(
  title: none,
  target: figure.where(kind: table)
)
#pagebreak()

#heading(numbering: none)[Danh mục ký hiệu và từ viết tắt]
#include "list_of_abbreviations.typ"
#pagebreak()

// Reset figure counters at the beginning of main content
#counter(heading).update(0)
#show link: underline

// ===== Main Content =====
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